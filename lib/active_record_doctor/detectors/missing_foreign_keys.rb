# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    class MissingForeignKeys < Base # :nodoc:
      @description = "detect foreign-key-like columns lacking an actual foreign key constraint"
      @config = {
        ignore_tables: {
          description: "tables whose columns should not be checked",
          global: true
        },
        ignore_columns: {
          description: "columns, written as table.column, that should not be checked"
        }
      }

      private

      def message(table:, column:)
        "create a foreign key on #{table}.#{column} - looks like an association without a foreign key constraint"
      end

      def detect
        each_table(except: config(:ignore_tables)) do |table|
          each_column(table, except: config(:ignore_columns)) do |column|
            # We need to skip polymorphic associations as they can reference
            # multiple tables but a foreign key constraint can reference
            # a single predefined table.
            next unless looks_like_foreign_key?(column)
            next if foreign_key?(table, column)
            next if polymorphic_foreign_key?(table, column)
            next if model_destroyed_async?(table, column)

            problem!(table: table, column: column.name)
          end
        end
      end

      def foreign_key?(table, column)
        connection.foreign_keys(table).any? do |foreign_key|
          foreign_key.options[:column] == column.name
        end
      end

      def polymorphic_foreign_key?(table, column)
        type_column_name = column.name.sub(/_id\Z/, "_type")
        connection.columns(table).any? do |another_column|
          another_column.name == type_column_name
        end
      end

      def model_destroyed_async?(table, column)
        # Check if there are any models having `has_many ..., dependent: :destroy_async`
        # referencing the specified table.
        models.any? do |model|
          model.reflect_on_all_associations(:has_many).any? do |reflection|
            reflection.options[:dependent] == :destroy_async &&
              reflection.foreign_key == column.name &&
              reflection.klass.table_name == table
          end
        end
      end
    end
  end
end
