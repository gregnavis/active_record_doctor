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

        def run(config, schema_inspector, io)
          new(config, schema_inspector, io).run
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

      def initialize(config, schema_inspector, io)
        @problems = []
        @config = config
        @schema_inspector = schema_inspector
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
        @schema_inspector.indexes(table_name).reject do |index|
          except.include?(index.name)
        end
      end

      def tables(except: [])
        @schema_inspector.tables.reject do |table|
          except.include?(table)
        end
      end

      def primary_key(table_name)
        primary_key_name = @schema_inspector.primary_key(table_name)
        return nil if primary_key_name.nil?

        column(table_name, primary_key_name)
      end

      def column(table_name, column_name)
        columns(table_name).find { |column| column.name == column_name }
      end

      def columns(table_name)
        @schema_inspector.columns(table_name)
      end

      def not_null_check_constraint_exists?(table, column)
        check_constraints(table).any? do |definition|
          definition =~ /\A#{column.name} IS NOT NULL\z/i ||
            definition =~ /\A#{connection.quote_column_name(column.name)} IS NOT NULL\z/i
        end
      end

      def foreign_keys(table_name)
        @schema_inspector.foreign_keys(table_name)
      end

      def check_constraints(table_name)
        @schema_inspector.check_constraints(table_name)
      end

      def models(except: [])
        ActiveRecord::Base.descendants.reject do |model|
          model.name.start_with?("HABTM_") || except.include?(model.name)
        end
      end

      def underscored_name
        self.class.underscored_name
      end
    end
  end
end
