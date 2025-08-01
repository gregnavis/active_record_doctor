# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    class IncorrectTimestampType < Base # :nodoc:
      @description = "Detects timestamp columns without timezone information on PostgreSQL."
      @config = {
        ignore_tables: {
          description: "Tables whose timestamp columns should not be checked.",
          global: true
        },
        ignore_columns: {
          description: "Columns that should not be checked.",
          global: true
        }
      }

      private

      def message(error: nil, table: nil, column: nil)
        return error if error

        <<~MESSAGE
          Incorrect timestamp type: The column `#{table}.#{column}` is `timestamp without time zone`.
          It's recommended to use `timestamp with time zone` for PostgreSQL.
        MESSAGE
      end

      def detect
        return unless Utils.postgresql?(connection)

        each_table(except: config(:ignore_tables)) do |table|
          each_column(table, except: config(:ignore_columns)) do |column|
            next unless timestamp_column?(column)

            # For PostgreSQL, column.sql_type will be 'timestamp without time zone'
            # or 'timestamp with time zone'.
            # Other databases might have different sql_type strings.
            if column.sql_type == "timestamp without time zone"
              problem!(table: table, column: column.name)
            end
          end
        end

        check_rails_default_timezone
        check_sql_adapter
      end

      def check_rails_default_timezone
        return unless defined?(Rails)
        return unless Rails.respond_to?(:initialized?) && Rails.initialized?
        return if Rails.application.config.active_record.default_timezone == :utc

        problem!(error: <<~MESSAGE)
          Rails time zone is not set to UTC.
          This can lead to incorrect handling of timestamps without timezone information.

          You can set it in your application configuration like this:

          Rails.application.config.time_zone = "UTC"
        MESSAGE
      end

      def check_sql_adapter
        return unless defined?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
        return if ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.datetime_type == :timestamptz

        problem!(error: <<~MESSAGE)
          PostgreSQL adapter's datetime type is not set to `timestamptz`.
          This can lead to incorrect handling of timestamps without timezone information.

          You can set it in your initializer like this:

          ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.datetime_type = :timestamptz
        MESSAGE
      end

      def timestamp_column?(column)
        [:datetime, :timestamp].include?(column.type)
      end
    end
  end
end
