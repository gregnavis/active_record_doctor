# frozen_string_literal: true

require "active_record_doctor/printers/io_printer"

module ActiveRecordDoctor
  module Tasks
    # Base class for all active_record_doctor tasks.
    class Base
      class << self
        attr_reader :description

        def run
          new.run
        end
      end

      def initialize(printer = ActiveRecordDoctor::Printers::IOPrinter.new)
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
        connection.indexes(table_name)
      end

      def tables
        connection.tables
      end

      def table_exists?(table_name)
        connection.table_exists?(table_name)
      end

      def views
        @views ||=
          if connection.respond_to?(:views)
            connection.views
          elsif connection.is_a?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
            ActiveRecord::Base.connection.execute(<<-SQL).map { |tuple| tuple.fetch("relname") }
              SELECT c.relname FROM pg_class c WHERE c.relkind IN ('m', 'v')
            SQL
          else # rubocop:disable Style/EmptyElse
            # We don't support this Rails/database combination yet.
            nil
          end
      end

      def hash_from_pairs(pairs)
        Hash[*pairs.flatten(1)]
      end

      def eager_load!
        Rails.application.eager_load!
      end

      def models
        ActiveRecord::Base.descendants
      end
    end
  end
end
