# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    # Find unindexed deleted_at columns.
    class UnindexedDeletedAt < Base
      PATTERN = [
        "deleted_at",
        "discarded_at"
      ].join("|").freeze

      @description = "Detect unindexed deleted_at columns"

      private

      def message(index:)
        # rubocop:disable Layout/LineLength
        "consider adding `WHERE deleted_at IS NULL` to #{index} - a partial index can speed lookups of soft-deletable models"
        # rubocop:enable Layout/LineLength
      end

      def detect
        connection.tables.select do |table|
          connection.columns(table).any? { |column| column.name =~ /^#{PATTERN}$/ }
        end.each do |table|
          connection.indexes(table).reject do |index|
            index.where =~ /\b#{PATTERN}\s+IS\s+NULL\b/i
          end.each do |index|
            problem!(
              index: index.name
            )
          end
        end
      end
    end
  end
end
