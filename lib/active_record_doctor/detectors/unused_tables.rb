# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    class UnusedTables < Base # :nodoc:
      @description = "detect tables not referenced by any model"
      @config = {
        ignore_tables: {
          description: "tables whose corresponding models should not be checked for existence",
          global: true
        }
      }

      private

      def message(table:)
        "The #{table} table is not referenced by any Rails model and can be dropped"
      end

      def detect
        each_table(except: config(:ignore_tables)) do |table|
          next if models.any? { |model| model.table_name == table }

          problem!(table: table)
        end
      end
    end
  end
end
