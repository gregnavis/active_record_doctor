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
        tables.each do |table|
          next if table == "schema_migrations"

          connection.foreign_keys(table).each do |foreign_key|
            from_column = column(table, foreign_key.column)
            to_table = foreign_key.to_table
            primary_key = primary_key(to_table)

            next if from_column.sql_type == primary_key.sql_type

            problem!(table: table, column: from_column.name)
          end
        end
      end
    end
  end
end
