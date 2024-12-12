# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    class TableWithoutTimestamps < Base # :nodoc:
      @description = "detect tables without created_at/updated_at columns"
      @config = {
        ignore_tables: {
          description: "tables whose timestamp columns existence should not be checked",
          global: true
        }
      }

      private

      TIMESTAMPS = {
        "created_at" => "created_on",
        "updated_at" => "updated_on"
      }.freeze

      def message(table:, column:)
        "add a #{column} column to #{table}"
      end

      def detect
        each_table(except: config(:ignore_tables)) do |table|
          TIMESTAMPS.each do |column, alternative_column|
            unless column(table, column) || column(table, alternative_column)
              problem!(table: table, column: column)
            end
          end
        end
      end
    end
  end
end
