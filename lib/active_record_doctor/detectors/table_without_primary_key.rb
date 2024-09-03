# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    class TableWithoutPrimaryKey < Base # :nodoc:
      @description = "detect tables without primary keys"
      @config = {
        ignore_tables: {
          description: "tables whose primary key existence should not be checked",
          global: true
        }
      }

      private

      def message(table:)
        "add a primary key to #{table}"
      end

      def detect
        each_table(except: config(:ignore_tables)) do |table|
          column = primary_key(table)
          problem!(table: table) unless column
        end
      end
    end
  end
end
