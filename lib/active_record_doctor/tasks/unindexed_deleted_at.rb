require "active_record_doctor/tasks/base"

module ActiveRecordDoctor
  module Tasks
    class UnindexedDeletedAt < Base
      @description = 'Detect unindexed deleted_at columns'

      def run
        success(connection.tables.select do |table|
          connection.columns(table).map(&:name).include?('deleted_at')
        end.flat_map do |table|
          connection.indexes(table).reject do |index|
            index.where =~ /\bdeleted_at\s+IS\s+NULL\b/i
          end.map do |index|
            index.name
          end
        end)
      end
    end
  end
end
