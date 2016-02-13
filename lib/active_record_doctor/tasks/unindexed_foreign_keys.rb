require "active_record_doctor/printers/io_printer"

module ActiveRecordDoctor
  module Tasks
    class UnindexedForeignKeys
      def self.run
        new.run
      end

      def initialize(printer: ActiveRecordDoctor::Printers::IOPrinter.new)
        @printer = printer
      end

      def run
        tables = connection.tables
        @printer.print_unindexed_foreign_keys(tables.select do |table|
          !["schema_migrations"].include?(table)
        end.map do |table|
          [
            table,
            connection.columns(table).select do |column|
              column.name.end_with?("_id") && !indexed?(table, column)
            end.map do |column|
              column.name
            end
          ]
        end.select do |table, columns|
          columns.present?
        end.to_h)
      end

      def indexed?(table, column)
        connection.indexes(table).any? do |index|
          index.columns.first == column.name
        end
      end

      def connection
        @connection ||= ActiveRecord::Base.connection
      end
    end
  end
end
