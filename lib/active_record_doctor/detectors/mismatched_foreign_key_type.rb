# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    class MismatchedForeignKeyType < Base # :nodoc:
      @description = "detect foreign key type mismatches"
      @config = {
        ignore_tables: {
          description: "tables whose foreign keys should not be checked",
          global: true
        },
        ignore_columns: {
          description: "foreign keys, written as table.column, that should not be checked"
        }
      }

      private

      def message(from_table:, from_column:, from_type:, to_table:, to_column:, to_type:)
        # rubocop:disable Layout/LineLength
        "#{from_table}.#{from_column} is a foreign key of type #{from_type} and references #{to_table}.#{to_column} of type #{to_type} - foreign keys should be of the same type as the referenced column"
        # rubocop:enable Layout/LineLength
      end

      def detect
        each_table(except: config(:ignore_tables)) do |table|
          each_foreign_key(table) do |foreign_key|
            from_column = column(table, foreign_key.column)

            next if config(:ignore_columns).include?("#{table}.#{from_column.name}")

            to_table = foreign_key.to_table
            to_column = column(to_table, foreign_key.primary_key)

            next if from_column.sql_type == to_column.sql_type

            problem!(
              from_table: table,
              from_column: from_column.name,
              from_type: from_column.sql_type,
              to_table: to_table,
              to_column: to_column.name,
              to_type: to_column.sql_type
            )
          end
        end
      end
    end
  end
end
