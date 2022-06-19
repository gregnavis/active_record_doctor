# frozen_string_literal: true

module ActiveRecordDoctor
  module Detectors
    # Base class for all active_record_doctor detectors.
    class Base
      BASE_CONFIG = {
        enabled: {
          description: "set to false to disable the detector altogether"
        }
      }.freeze

      class << self
        attr_reader :description

        def run(config, io)
          new(config, io).run
        end

        def underscored_name
          name.demodulize.underscore.to_sym
        end

        def config
          @config.merge(BASE_CONFIG)
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

        detect if config(:enabled)
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

      def not_null_check_constraint_exists?(table, column)
        check_constraints(table).any? do |definition|
          definition =~ /\A#{column.name} IS NOT NULL\z/i ||
            definition =~ /\A#{connection.quote_column_name(column.name)} IS NOT NULL\z/i
        end
      end

      def check_constraints(table_name)
        # ActiveRecord 6.1+
        if connection.respond_to?(:supports_check_constraints?) && connection.supports_check_constraints?
          connection.check_constraints(table_name).select(&:validated?).map(&:expression)
        elsif postgresql?
          definitions =
            connection.select_values(<<-SQL)
              SELECT pg_get_constraintdef(oid, true)
              FROM pg_constraint
              WHERE contype = 'c'
                AND convalidated
                AND conrelid = #{connection.quote(table_name)}::regclass
            SQL

          definitions.map { |definition| definition[/CHECK \((.+)\)/m, 1] }
        else
          # We don't support this Rails/database combination yet.
          []
        end
      end

      def models(except: [])
        ActiveRecord::Base.descendants.reject do |model|
          model.name.start_with?("HABTM_") || except.include?(model.name)
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
