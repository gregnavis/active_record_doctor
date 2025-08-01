# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    class ShortPrimaryKeyType < Base # :nodoc:
      @description = "detect primary keys with short integer types"
      @config = {
        ignore_tables: {
          description: "tables whose primary keys should not be checked",
          global: true
        }
      }

      private

      def message(table:, column:)
        "change the type of #{table}.#{column} to bigint"
      end

      def detect
        return if ActiveRecordDoctor::Utils.sqlite?

        each_table(except: config(:ignore_tables)) do |table|
          columns = primary_key(table)
          next if columns.nil? || columns.size > 1

          column = columns.first
          next if !integer?(column) || bigint?(column)

          problem!(table: table, column: column.name)
        end
      end

      def bigint?(column)
        if column.respond_to?(:bigint?)
          column.bigint?
        else
          /\Abigint\b/.match?(column.sql_type)
        end
      end

      def integer?(column)
        column.type == :integer
      end
    end
  end
end
