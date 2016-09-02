require "active_record_doctor/compatibility"
require "active_record_doctor/printers/io_printer"

module ActiveRecordDoctor
  module Tasks
    class UnindexedForeignKeys
      include Compatibility

      def self.run
        new.run
      end

      def initialize(printer: ActiveRecordDoctor::Printers::IOPrinter.new)
        @printer = printer
      end

      def run
        @printer.print_unindexed_foreign_keys(unindexed_foreign_keys)
      end

      private

      def unindexed_foreign_keys
        hash_from_pairs(connection_tables.select do |table|
          "schema_migrations" != table
        end.map do |table|
          [
            table,
            connection.columns(table).select do |column|
              foreign_key?(table, column) &&
                !indexed?(table, column) &&
                !indexed_as_polymorphic?(table, column)
            end.map(&:name)
          ]
        end.select do |table, columns|
          !columns.empty?
        end)
      end

      def foreign_key?(table, column)
        column.name.end_with?("_id")
      end

      def indexed?(table, column)
        connection.indexes(table).any? do |index|
          index.columns.first == column.name
        end
      end

      def indexed_as_polymorphic?(table, column)
        type_column_name = column.name.sub(/_id\Z/, '_type')
        connection.indexes(table).any? do |index|
          index.columns == [type_column_name, column.name]
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
