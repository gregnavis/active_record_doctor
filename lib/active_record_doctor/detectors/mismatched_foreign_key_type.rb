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

      def message(table:, column:)
        # rubocop:disable Layout/LineLength
        "#{table}.#{column} references a column of different type - foreign keys should be of the same type as the referenced column"
        # rubocop:enable Layout/LineLength
      end

      def detect
        tables(except: config(:ignore_tables)).each do |table|
          connection.foreign_keys(table).each do |foreign_key|
            from_column = column(table, foreign_key.column)

            next if config(:ignore_columns).include?("#{table}.#{from_column.name}")

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
