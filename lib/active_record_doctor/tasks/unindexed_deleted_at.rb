# frozen_string_literal: true

require "active_record_doctor/tasks/base"

module ActiveRecordDoctor
  module Tasks
    # Find unindexed deleted_at columns.
    class UnindexedDeletedAt < Base
      PATTERN = [
        "deleted_at",
        "discarded_at"
      ].join("|").freeze

      @description = "Detect unindexed deleted_at columns"

      def run
        success(connection.tables.select do |table|
          connection.columns(table).any? { |column| column.name =~ /^#{PATTERN}$/ }
        end.flat_map do |table|
          connection.indexes(table).reject do |index|
            index.where =~ /\b#{PATTERN}\s+IS\s+NULL\b/i
          end.map do |index|
            index.name
          end
        end)
      end
    end
  end
end
