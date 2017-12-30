require "active_record_doctor/compatibility"
require "active_record_doctor/printers/io_printer"

module ActiveRecordDoctor
  module Tasks
    class UnindexedDeletedAt
      include Compatibility

      def self.run
        new.run
      end

      def initialize(printer: ActiveRecordDoctor::Printers::IOPrinter.new)
        @printer = printer
      end

      def run
        @printer.print_unindexed_deleted_at(unindexed_deleted_at)
      end

      private

      def unindexed_deleted_at
        connection.tables.select do |table|
          connection.columns(table).map(&:name).include?('deleted_at')
        end.flat_map do |table|
          connection.indexes(table).reject do |index|
            index.where =~ /\bdeleted_at\s+IS\s+NULL\b/i
          end.map do |index|
            index.name
          end
        end
      end

      def connection
        @connection ||= ActiveRecord::Base.connection
      end
    end
  end
end
