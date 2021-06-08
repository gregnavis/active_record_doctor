# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    # Find primary keys having short integer types.
    # Starting from rails 5.1, the default type is :bigint.
    class ShortPrimaryKeyType < Base
      VALID_TYPES = ["bigint", "bigserial", "uuid"].freeze

      @description = "Detect primary keys with short integer types"

      def detect
        problems(hash_from_pairs(tables.reject do |table|
          table == "schema_migrations" || valid_type?(primary_key(table))
        end.map do |table|
          [table, primary_key(table).name]
        end))
      end

      private

      def valid_type?(column)
        VALID_TYPES.any? do |type|
          column.sql_type == type
        end
      end
    end
  end
end
