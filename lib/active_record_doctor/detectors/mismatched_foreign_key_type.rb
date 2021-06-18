# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    # Check whether primary keys and foreign keys use the same type.
    class MismatchedForeignKeyType < Base
      @description = "Check whether primary keys and foreign keys use the same type"

      private

      def message(table:, column:)
        # rubocop:disable Layout/LineLength
        "#{table}.#{column} references a column of different type - foreign keys should be of the same type as the referenced column"
        # rubocop:enable Layout/LineLength
      end

      def detect
        tables.reject do |table|
          table == "schema_migrations"
        end.map do |table|
          [
            table,
            mismatched_foreign_keys(table).map(&:column)
          ]
        end.reject do |_table, foreign_keys|
          foreign_keys.empty?
        end.each do |table, foreign_keys|
          foreign_keys.each do |foreign_key|
            problem!(
              table: table,
              column: foreign_key
            )
          end
        end
      end

      def mismatched_foreign_keys(table)
        connection.foreign_keys(table).reject do |foreign_key|
          from_column = column(table, foreign_key.column)
          to_table = foreign_key.to_table
          primary_key = primary_key(to_table)

          from_column.sql_type == primary_key.sql_type
        end
      end
    end
  end
end
