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

      def initialize(config:, logger:, io:)
        @problems = []
        @config = config
        @logger = logger
        @io = io
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
        connection.indexes(table_name)
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

      def models
        ActiveRecord::Base.descendants
      end

      def underscored_name
        self.class.underscored_name
      end

      def postgresql?
        ["PostgreSQL", "PostGIS"].include?(connection.adapter_name)
      end

      def each_model(except: [], abstract: nil, existing_tables_only: false)
        log("Iterating over Active Record models") do
          models.each do |model|
            case
            when model.name.start_with?("HABTM_")
              log("#{model.name} - has-belongs-to-many model; skipping")
            when except.include?(model.name)
              log("#{model.name} - ignored via the configuration; skipping")
            when abstract && !model.abstract_class?
              log("#{model.name} - non-abstract model; skipping")
            when abstract == false && model.abstract_class?
              log("#{model.name} - abstract model; skipping")
            when existing_tables_only && model.table_name && !model.table_exists?
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
        indexes = connection.indexes(table_name)

        message =
          if multicolumn_only
            "Iterating over multi-column indexes on #{table_name}"
          else
            "Iterating over indexes on #{table_name}"
          end

        log(message) do
          indexes.each do |index|
            case
            when except.include?(index.name)
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
          connection.columns(model.table_name).each do |column|
            case
            when except.include?("#{model.name}.#{column.name}")
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
          connection.columns(table_name).each do |column|
            case
            when except.include?("#{table_name}.#{column.name}")
              log("#{column.name} - ignored via the configuration; skipping")
            when only.nil? || only.include?(column.name)
              log(column.name.to_s) do
                yield(column)
              end
            end
          end
        end
      end

      def each_foreign_key(table_name)
        log("Iterating over foreign keys on #{table_name}") do
          connection.foreign_keys(table_name).each do |foreign_key|
            log("#{foreign_key.name} - #{foreign_key.from_table}(#{foreign_key.options[:column]}) to #{foreign_key.to_table}(#{foreign_key.options[:primary_key]})") do # rubocop:disable Layout/LineLength
              yield(foreign_key)
            end
          end
        end
      end

      def each_table(except: [])
        tables =
          if ActiveRecord::VERSION::STRING >= "5.1"
            connection.tables
          else
            connection.data_sources
          end

        log("Iterating over tables") do
          tables.each do |table|
            case
            when except.include?(table)
              log("#{table} - ignored via the configuration; skipping")
            else
              log(table) do
                yield(table)
              end
            end
          end
        end
      end

      def each_association(model, except: [], type: [:has_many, :has_one, :belongs_to], has_scope: nil, through: nil)
        type = Array(type)

        log("Iterating over associations on #{model.name}") do
          associations = []
          type.each do |type1|
            associations.concat(model.reflect_on_all_associations(type1))
          end

          associations.each do |association|
            case
            when except.include?("#{model.name}.#{association.name}")
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
    end
  end
end
