require "active_record_doctor/printers/io_printer"

module ActiveRecordDoctor
  module Tasks
    class ExtraneousIndexes
      def self.run
        new.run
      end

      def initialize(printer: ActiveRecordDoctor::Printers::IOPrinter.new)
        @printer = printer
      end

      def run
        @printer.print_extraneous_indexes(extraneous_indexes)
      end

      private

      def extraneous_indexes
        @extraneous_indexes ||=
          tables.reject do |table|
            "schema_migrations" == table
          end.flat_map do |table|
            indexes = indexes(table)
            maximum_indexes = indexes.select do |index|
              indexes.all? do |another_index|
                index == another_index || !prefix?(index, another_index)
              end
            end

            indexes.reject do |index|
              maximum_indexes.include?(index)
            end.map do |extraneous_index|
              [
                extraneous_index.name,
                maximum_indexes.find do |maximum_index|
                  prefix?(extraneous_index, maximum_index)
                end.name
              ]
            end
          end
      end

      def prefix?(lhs, rhs)
       lhs.columns.count <= rhs.columns.count &&
        rhs.columns[0...lhs.columns.count] == lhs.columns
      end

      def indexes(table_name)
        @connection.indexes(table_name)
      end

      def tables
        @tables ||= connection.tables
      end

      def connection
        @connection ||= ActiveRecord::Base.connection
      end
    end
  end
end
