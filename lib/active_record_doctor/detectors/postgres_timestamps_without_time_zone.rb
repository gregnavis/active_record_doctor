# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    class PostgresTimestampsWithoutTimeZone < Base # :nodoc:
      @description = "detect timestamp columns without time zone information in PostgreSQL"
      @config = {
        ignore_tables: {
          description: "tables whose timestamp columns should not be checked",
          global: true
        },
        ignore_columns: {
          description: "columns, written as table.column, that should not be checked"
        },
        ignore_datetime_type: {
          description: "don't check ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.datetime_type"
        }
      }

      private

      def message(problem: nil, table: nil, column: nil, type: nil)
        case problem
        when :column_type
          "#{table}.#{column} should be using the recommended TIMESTAMP WITH TIME ZONE type"

        when :default_datetime_type
          "PostgreSQL default datetime type should be set to :timestamptz, not #{type.inspect}"

        else
          raise ArgumentError.new("unknown problem #{problem.inspect}")
        end
      end

      def detect
        return unless Utils.postgresql?(connection)

        # The default datetime type is shared by all PostgreSQL databases, so
        # it's reported once.
        if !config(:ignore_datetime_type) &&
           !@datetime_type_checked &&
           ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.datetime_type != :timestamptz
          problem!(
            problem: :default_datetime_type,
            type: ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.datetime_type
          )
        end
        @datetime_type_checked = true

        each_table(except: config(:ignore_tables)) do |table|
          each_column(table, except: config(:ignore_columns)) do |column|
            next if !column.sql_type.match?(/\Atimestamp(\(\d+\))? without time zone\z/)

            problem!(problem: :column_type, table: table, column: column.name)
          end
        end
      end
    end
  end
end
