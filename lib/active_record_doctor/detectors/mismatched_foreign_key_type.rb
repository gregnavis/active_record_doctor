# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    # Check whether primary keys and foreign keys use the same type.
    class MismatchedForeignKeyType < Base
      @description = "Check whether primary keys and foreign keys use the same type"

      def run
        problems(hash_from_pairs(tables.reject do |table|
          table == "schema_migrations"
        end.map do |table|
          [
            table,
            mismatched_foreign_keys(table).map(&:column)
          ]
        end.reject do |_table, foreign_keys|
          foreign_keys.empty?
        end))
      end

      private

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
