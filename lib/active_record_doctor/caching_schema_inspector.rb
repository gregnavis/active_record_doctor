# frozen_string_literal: true

module ActiveRecordDoctor
  class CachingSchemaInspector # :nodoc:
    def initialize(connection)
      @connection = connection
      @primary_keys = {}
      @indexes = {}
      @foreign_keys = {}
      @check_constraints = {}
    end

    def tables
      @tables ||= @connection.tables
    end

    def data_sources
      @data_sources ||= @connection.data_sources
    end

    def views
      @views ||= @connection.views
    end

    def primary_key(table_name)
      @primary_keys[table_name] ||= @connection.primary_key(table_name)
    end

    def columns(table_name)
      @connection.schema_cache.columns(table_name)
    end

    def indexes(table_name)
      @indexes.fetch(table_name) do
        @indexes[table_name] = @connection.indexes(table_name)
      end
    end

    def foreign_keys(table_name)
      @foreign_keys[table_name] ||= @connection.foreign_keys(table_name)
    end

    def check_constraints(table_name)
      @check_constraints[table_name] ||=
        if @connection.supports_check_constraints?
          @connection.check_constraints(table_name).select(&:validated?).map(&:expression)
        else
          # We don't support this Rails/database combination yet.
          []
        end
    end
  end
end
