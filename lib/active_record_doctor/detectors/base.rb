# frozen_string_literal: true

module ActiveRecordDoctor
  module Detectors
    # Base class for all active_record_doctor detectors.
    class Base
      class << self
        attr_reader :description, :config

        def run(config, io)
          new(config, io).run
        end

        def underscored_name
          name.demodulize.underscore.to_sym
        end

        def locals_and_globals
          locals = []
          globals = []

          config.each do |key, metadata|
            locals << key
            globals << key if metadata[:global]
          end

          [locals, globals]
        end
      end

      def initialize(config, io)
        @problems = []
        @config = config
        @io = io
      end

      def run
        @problems = []

        detect
        @problems.each do |problem|
          @io.puts(message(**problem))
        end

        success = @problems.empty?
        @problems = nil
        success
      end

      private

      def config(key)
        local = @config.detectors.fetch(underscored_name).fetch(key)
        return local if !self.class.config.fetch(key)[:global]

        global = @config.globals[key]
        return local if global.nil?

        # Right now, all globals are arrays so we can merge them here. Once
        # we add non-array globals we'll need to support per-global merging.
        Array.new(local).concat(global)
      end

      def detect
        raise("#detect should be implemented by a subclass")
      end

      def message(**_attrs)
        raise("#message should be implemented by a subclass")
      end

      def problem!(**attrs)
        @problems << attrs
      end

      def warning(message)
        puts(message)
      end

      def connection
        @connection ||= ActiveRecord::Base.connection
      end

      def indexes(table_name, except: [])
        connection.indexes(table_name).reject do |index|
          except.include?(index.name)
        end
      end

      def tables(except: [])
        tables =
          if ActiveRecord::VERSION::STRING >= "5.1"
            connection.tables
          else
            connection.data_sources
          end

        tables.reject do |table|
          except.include?(table)
        end
      end

      def primary_key(table_name)
        primary_key_name = connection.primary_key(table_name)
        return nil if primary_key_name.nil?

        column(table_name, primary_key_name)
      end

      def column(table_name, column_name)
        connection.columns(table_name).find { |column| column.name == column_name }
      end

      def views
        @views ||=
          if connection.respond_to?(:views)
            connection.views
          elsif postgresql?
            ActiveRecord::Base.connection.select_values(<<-SQL)
              SELECT relname FROM pg_class WHERE relkind IN ('m', 'v')
            SQL
          elsif connection.adapter_name == "Mysql2"
            ActiveRecord::Base.connection.select_values(<<-SQL)
              SHOW FULL TABLES WHERE table_type = 'VIEW'
            SQL
          else
            # We don't support this Rails/database combination yet.
            []
          end
      end

      def models(except: [])
        ActiveRecord::Base.descendants.reject do |model|
          model.name.to_s.start_with?("HABTM_") || except.include?(model.name)
        end
      end

      def underscored_name
        self.class.underscored_name
      end

      def postgresql?
        ["PostgreSQL", "PostGIS"].include?(connection.adapter_name)
      end
    end
  end
end
