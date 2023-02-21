# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    class UnindexedDeletedAt < Base # :nodoc:
      @description = "detect indexes that exclude deletion timestamp columns"
      @config = {
        ignore_tables: {
          description: "tables whose indexes should not be checked",
          global: true
        },
        ignore_columns: {
          description: "specific columns, written as table.column, that should not be reported as unindexed"
        },
        ignore_indexes: {
          description: "specific indexes that should not be reported as excluding a timestamp column"
        },
        column_names: {
          description: "deletion timestamp column names"
        }
      }

      private

      def message(index:, column_name:)
        # rubocop:disable Layout/LineLength
        "consider adding `WHERE #{column_name} IS NULL` or `WHERE #{column_name} IS NOT NULL` to #{index} - a partial index can speed lookups of soft-deletable models"
        # rubocop:enable Layout/LineLength
      end

      def detect
        each_table(except: config(:ignore_tables)) do |table|
          each_column(table, only: config(:column_names), except: config(:ignore_columns)) do |column|
            each_index(table, except: config(:ignore_indexes)) do |index|
              next if index.where =~ /\b#{column.name}\s+IS\s+(NOT\s+)?NULL\b/i

              problem!(index: index.name, column_name: column.name)
            end
          end
        end
      end
    end
  end
end
