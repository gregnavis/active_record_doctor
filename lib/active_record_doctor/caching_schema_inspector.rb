# frozen_string_literal: true

module ActiveRecordDoctor
  class CachingSchemaInspector # :nodoc:
    def initialize(connection)
      @connection = connection
      @indexes = {}
      @foreign_keys = {}
      @check_constraints = {}
    end

    def tables
      @tables ||=
        if ActiveRecord::VERSION::STRING >= "5.1"
          @connection.tables
        else
          @connection.data_sources
        end
    end

    def primary_key(table_name)
      @connection.schema_cache.primary_keys(table_name)
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
      @foreign_keys.fetch(table_name) do
        @foreign_keys[table_name] = @connection.foreign_keys(table_name)
      end
    end

    def check_constraints(table_name)
      @check_constraints.fetch(table_name) do
        # ActiveRecord 6.1+
        if @connection.respond_to?(:supports_check_constraints?) && @connection.supports_check_constraints?
          @connection.check_constraints(table_name).select(&:validated?).map(&:expression)
        elsif postgresql?
          definitions =
            @connection.select_values(<<-SQL)
              SELECT pg_get_constraintdef(oid, true)
              FROM pg_constraint
              WHERE contype = 'c'
                AND convalidated
                AND conrelid = #{@connection.quote(table_name)}::regclass
            SQL

          definitions.map { |definition| definition[/CHECK \((.+)\)/m, 1] }
        else
          # We don't support this Rails/database combination yet.
          []
        end
      end
    end

    private

    def postgresql?
      ["PostgreSQL", "PostGIS"].include?(@connection.adapter_name)
    end
  end
end
