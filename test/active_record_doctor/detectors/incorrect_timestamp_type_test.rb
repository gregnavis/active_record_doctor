# frozen_string_literal: true

class ActiveRecordDoctor::Detectors::IncorrectTimestampTypeTest < Minitest::Test
  def setup
    skip unless postgresql?
    ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.datetime_type = :timestamptz
  end

  def test_timestamp_without_time_zone_is_error
    Context.create_table(:events) do |t|
      t.column :occurred_at, :timestamp, null: false
    end.define_model

    # Simulate column.sql_type as 'timestamp without time zone'
    ActiveRecord::Base.connection.change_column :events, :occurred_at, "timestamp without time zone"

    assert_problems(<<~OUTPUT)
      Incorrect timestamp type: The column `events.occurred_at` is `timestamp without time zone`.
      It's recommended to use `timestamp with time zone` for PostgreSQL.
    OUTPUT
  end

  def test_timestamp_with_time_zone_is_ok
    Context.create_table(:events) do |t|
      t.timestamptz :occurred_at, null: false
    end.define_model

    refute_problems
  end

  def test_ignore_tables
    Context.create_table(:events) do |t|
      t.column :occurred_at, :timestamp, null: false
    end.define_model

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :incorrect_timestamp_type,
          ignore_tables: ["events"]
      end
    CONFIG

    refute_problems
  end

  def test_ignore_columns
    Context.create_table(:events) do |t|
      t.column :occurred_at, :timestamp, null: false
    end.define_model

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :incorrect_timestamp_type,
          ignore_columns: ["events.occurred_at"]
      end
    CONFIG

    refute_problems
  end

  def test_no_timestamp_columns_is_ok
    Context.create_table(:events) do |t|
      t.string :name
    end.define_model

    refute_problems
  end

  def test_postgresql_adapter_datetime_type_timestamptz
    return unless defined?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)

    assert_equal ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.datetime_type, :timestamptz
  end

  def test_rails_config_time_zone_and_default_timezone
    return unless defined?(Rails)
    return unless Rails.respond_to?(:application)

    # assert_equal ActiveRecord::Base.default_timezone, :utc
    # Ensure that the default timezone is set to UTC in the application config
    assert_equal Rails.application.config.active_record.default_timezone, :utc
  end
end
