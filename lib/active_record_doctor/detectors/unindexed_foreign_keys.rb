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

      def message(table:, column:)
        # rubocop:disable Layout/LineLength
        "add an index on #{table}.#{column} - foreign keys are often used in database lookups and should be indexed for performance reasons"
        # rubocop:enable Layout/LineLength
      end

      def detect
        tables(except: config(:ignore_tables)).each do |table|
          connection.columns(table).each do |column|
            next if config(:ignore_columns).include?("#{table}.#{column.name}")

            next unless foreign_key?(column)
            next if indexed?(table, column)
            next if indexed_as_polymorphic?(table, column)

            problem!(table: table, column: column.name)
          end
        end
      end

      def foreign_key?(column)
        column.name.end_with?("_id")
      end

      def indexed?(table, column)
        connection.indexes(table).any? do |index|
          index.columns.first == column.name
        end
      end

      def indexed_as_polymorphic?(table, column)
        type_column_name = column.name.sub(/_id\Z/, "_type")
        connection.indexes(table).any? do |index|
          index.columns == [type_column_name, column.name]
        end
      end
    end
  end
end
