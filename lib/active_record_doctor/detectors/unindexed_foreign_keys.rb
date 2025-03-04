# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    class UnindexedForeignKeys < Base # :nodoc:
      @description = "detect unindexed foreign keys"
      @config = {
        ignore_tables: {
          description: "tables whose foreign keys should not be checked",
          global: true
        },
        ignore_columns: {
          description: "columns, written as table.column, that should not be checked"
        }
      }

      private

      def message(table:, columns:)
        # rubocop:disable Layout/LineLength
        "add an index on #{table}(#{columns.join(', ')}) - foreign keys are often used in database lookups and should be indexed for performance reasons"
        # rubocop:enable Layout/LineLength
      end

      def detect
        each_table(except: config(:ignore_tables)) do |table|
          each_column(table, except: config(:ignore_columns)) do |column|
            next unless looks_like_foreign_key?(column) || foreign_key?(table, column)
            next if indexed?(table, column)
            next if indexed_as_polymorphic?(table, column)
            next if connection.primary_key(table) == column.name

            type_column_name = type_column_name(column)

            columns =
              if column_exists?(table, type_column_name)
                [type_column_name, column.name]
              else
                [column.name]
              end

            problem!(table: table, columns: columns)
          end
        end
      end

      def foreign_key?(table, column)
        connection.foreign_keys(table).any? do |foreign_key|
          foreign_key.column == column.name
        end
      end

      def indexed?(table, column)
        connection.indexes(table).any? do |index|
          index.columns.first == column.name ||
            (connection.primary_key(table).is_a?(Array) &&
             connection.primary_key(table).include?(column.name))
        end
      end

      def indexed_as_polymorphic?(table, column)
        connection.indexes(table).any? do |index|
          index.columns[0, 2] == [type_column_name(column), column.name]
        end
      end

      def column_exists?(table, column_name)
        connection.columns(table).any? { |column| column.name == column_name }
      end

      def type_column_name(column)
        if column.name.end_with?("_id")
          column.name.sub(/_id\Z/, "_type")
        else
          "#{column.name}_type"
        end
      end
    end
  end
end
