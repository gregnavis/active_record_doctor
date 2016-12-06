require "active_record_doctor/compatibility"
require "active_record_doctor/printers/io_printer"

module ActiveRecordDoctor
  module Tasks
    class MissingForeignKeys
      include Compatibility

      def self.run
        new.run
      end

      def initialize(printer: ActiveRecordDoctor::Printers::IOPrinter.new)
        @printer = printer
      end

      def run
        @printer.print_missing_foreign_keys(missing_foreign_keys)
      end

      private

      def missing_foreign_keys
        hash_from_pairs(connection_tables.select do |table|
          "schema_migrations" != table
        end.map do |table|
          [
            table,
            connection.columns(table).select do |column|
              # We need to skip polymorphic associations as they can reference
              # multiple tables but a foreign key constraint can reference
              # a single predefined table.
              id?(table, column) &&
                !foreign_key?(table, column) &&
                !polymorphic_foreign_key?(table, column)
            end.map(&:name)
          ]
        end.select do |table, columns|
          !columns.empty?
        end)
      end

      def id?(table, column)
        column.name.end_with?("_id")
      end

      def foreign_key?(table, column)
        connection.foreign_keys(table).any? do |foreign_key|
          foreign_key.options[:column] == column.name
        end
      end

      def polymorphic_foreign_key?(table, column)
        type_column_name = column.name.sub(/_id\Z/, '_type')
        connection.columns(table).any? do |another_column|
          another_column.name == type_column_name
        end
      end

      def connection
        @connection ||= ActiveRecord::Base.connection
      end

      def hash_from_pairs(pairs)
        Hash[*pairs.flatten(1)]
      end
    end
  end
end
