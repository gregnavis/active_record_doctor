# frozen_string_literal: true

module ActiveRecordDoctor
  module Detectors
    # Base class for all active_record_doctor detectors.
    class Base
      class << self
        attr_reader :description

        def run
          new.run
        end
      end

      private

      def problems(problems, options = {})
        [problems, options]
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

      def primary_key(table_name)
        primary_key_name = connection.primary_key(table_name)
        column(table_name, primary_key_name)
      end

      def column(table_name, column_name)
        connection.columns(table_name).find { |column| column.name == column_name }
      end

      def views
        @views ||=
          if connection.respond_to?(:views)
            connection.views
          elsif connection.adapter_name == "PostgreSQL"
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
