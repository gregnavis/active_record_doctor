require "active_record_doctor/printers/io_printer"

module ActiveRecordDoctor
  module Tasks
    class Base
      def self.run
        new.run
      end

      def initialize(printer: ActiveRecordDoctor::Printers::IOPrinter.new)
        @printer = printer
      end

      private

      def success(result)
        [result, true]
      end

      def connection
        @connection ||= ActiveRecord::Base.connection
      end

      def indexes(table_name)
        @connection.indexes(table_name)
      end

      def tables
        @tables ||= 
          if Rails::VERSION::MAJOR == 5
            connection.data_sources
          else
            connection.tables
          end
      end

      def hash_from_pairs(pairs)
        Hash[*pairs.flatten(1)]
      end
    end
  end
end
