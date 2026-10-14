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

        def run(*args, **kwargs, &block)
          new(*args, **kwargs, &block).run
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

      def initialize(config:, logger:, io:, schema_inspector:)
        @problems = []
        @config = config
        @logger = logger
        @io = io
        @schema_inspector = schema_inspector
      end

      def run
        log(underscored_name) do
          @problems = []

          if config(:enabled)
            detect
          else
            log("disabled; skipping")
          end

          @problems.each do |problem|
            @io.puts(message(**problem))
          end

          success = @problems.empty?
          if success
            log("No problems found")
          else
            log("Found #{@problems.count} problem(s)")
          end
          @problems = nil
          success
        end
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

      def log(message, &block)
        @logger.log(message, &block)
      end

      def problem!(**attrs)
        log("Problem found") do
          attrs.each do |key, value|
            log("#{key}: #{value.inspect}")
          end
        end
        @problems << attrs
      end

      def warning(message)
        puts(message)
      end

      def connection
        @connection ||= ActiveRecord::Base.connection
      end

      def indexes(table_name)
        @schema_inspector.indexes(table_name)
      end

      def tables
        @schema_inspector.tables
      end

      def data_sources
        @schema_inspector.data_sources
      end

      def views
        @schema_inspector.views
      end

      def primary_key(table_name)
        @schema_inspector.primary_key(table_name)
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

      def table_exists?(table_name)
        tables.include?(table_name)
      end

      def data_source_exists?(name)
        data_sources.include?(name)
      end

      def check_constraints(table_name)
        @schema_inspector.check_constraints(table_name)
      end

      def foreign_keys(table_name)
        @schema_inspector.foreign_keys(table_name)
      end

      def models
        ActiveRecord::Base.descendants.sort_by(&:name)
      end

      def underscored_name
        self.class.underscored_name
      end

      def each_model(except: [], abstract: nil, existing_tables_only: false)
        log("Iterating over Active Record models") do
          models.each do |model|
            case
            when model.name.start_with?("HABTM_")
              log("#{model.name} - has-belongs-to-many model; skipping")
            when ignored?(model.name, except)
              log("#{model.name} - ignored via the configuration; skipping")
            when abstract && !model.abstract_class?
              log("#{model.name} - non-abstract model; skipping")
            when abstract == false && model.abstract_class?
              log("#{model.name} - abstract model; skipping")
            when existing_tables_only && (model.table_name.nil? || !table_exists?(model.table_name))
              log("#{model.name} - backed by a non-existent table #{model.table_name}; skipping")
            else
              log(model.name) do
                yield(model)
              end
            end
          end
        end
      end

      def each_index(table_name, except: [], multicolumn_only: false)
        indexes = indexes(table_name)

        message =
          if multicolumn_only
            "Iterating over multi-column indexes on #{table_name}"
          else
            "Iterating over indexes on #{table_name}"
          end

        log(message) do
          indexes.each do |index|
            case
            when ignored?(index.name, except)
              log("#{index.name} - ignored via the configuration; skipping")
            when multicolumn_only && !index.columns.is_a?(Array)
              log("#{index.name} - single-column index; skipping")
            else
              log("Index #{index.name} on #{table_name}") do
                yield(index, indexes)
              end
            end
          end
        end
      end

      def each_attribute(model, except: [], type: nil)
        log("Iterating over attributes of #{model.name}") do
          columns(model.table_name).each do |column|
            case
            when ignored?("#{model.name}.#{column.name}", except)
              log("#{model.name}.#{column.name} - ignored via the configuration; skipping")
            when type && !Array(type).include?(column.type)
              log("#{model.name}.#{column.name} - ignored due to the #{column.type} type; skipping")
            else
              log("#{model.name}.#{column.name}") do
                yield(column)
              end
            end
          end
        end
      end

      def each_column(table_name, only: nil, except: [])
        log("Iterating over columns of #{table_name}") do
          columns(table_name).each do |column|
            case
            when ignored?("#{table_name}.#{column.name}", except)
              log("#{column.name} - ignored via the configuration; skipping")
            when only.nil? || only.include?(column.name)
              log(column.name.to_s) do
                yield(column)
              end
            end
          end
        end
      end

      def looks_like_foreign_key?(column)
        type = column.type.to_s

        column.name.end_with?("_id") &&
          (type == "integer" || type.include?("uuid"))
      end

      def each_foreign_key(table_name)
        log("Iterating over foreign keys on #{table_name}") do
          foreign_keys(table_name).each do |foreign_key|
            log("#{foreign_key.name} - #{foreign_key.from_table}(#{foreign_key.options[:column]}) to #{foreign_key.to_table}(#{foreign_key.options[:primary_key]})") do # rubocop:disable Layout/LineLength
              yield(foreign_key)
            end
          end
        end
      end

      def each_table(except: [])
        log("Iterating over tables") do
          tables.each do |table|
            case
            when ignored?(table, except)
              log("#{table} - ignored via the configuration; skipping")
            else
              log(table) do
                yield(table)
              end
            end
          end
        end
      end

      def each_data_source(except: [])
        log("Iterating over data sources") do
          data_sources.each do |data_source|
            if ignored?(data_source, except)
              log("#{data_source} - ignored via the configuration; skipping")
            else
              log(data_source) do
                yield(data_source)
              end
            end
          end
        end
      end

      def each_association(model, except: [], type: [:has_many, :has_one, :belongs_to], has_scope: nil, through: nil)
        type = Array(type)

        log("Iterating over associations on #{model.name}") do
          associations = type.map do |type1|
            # Skip inherited associations from STI to prevent them
            # from being reported multiple times on subclasses.
            model.reflect_on_all_associations(type1) - model.superclass.reflect_on_all_associations(type1)
          end.flatten

          associations.each do |association|
            case
            when ignored?("#{model.name}.#{association.name}", except)
              log("#{model.name}.#{association.name} - ignored via the configuration; skipping")
            when through && !association.is_a?(ActiveRecord::Reflection::ThroughReflection)
              log("#{model.name}.#{association.name} - is not a through association; skipping")
            when through == false && association.is_a?(ActiveRecord::Reflection::ThroughReflection)
              log("#{model.name}.#{association.name} - is a through association; skipping")
            when has_scope && association.scope.nil?
              log("#{model.name}.#{association.name} - doesn't have a scope; skipping")
            when has_scope == false && association.scope
              log("#{model.name}.#{association.name} - has a scope; skipping")
            else
              log("#{association.macro} :#{association.name}") do
                yield(association)
              end
            end
          end
        end
      end

      def ignored?(name, patterns)
        patterns.any? { |pattern| pattern === name || name == pattern.to_s } # rubocop:disable Style/CaseEquality
      end
    end
  end
end
