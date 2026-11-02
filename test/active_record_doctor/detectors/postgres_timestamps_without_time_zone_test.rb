# frozen_string_literal: true

class ActiveRecordDoctor::Detectors::PostgresTimestampsWithoutTimeZoneTest < Minitest::Test
  def setup
    super

    skip unless postgresql?
  end

  def test_timestamp_without_time_zone_is_error
    Context.create_table(:events) do |t|
      t.column :occurred_at, "TIMESTAMP WITHOUT TIME ZONE"
    end.define_model

    assert_problems(<<~OUTPUT)
      events.occurred_at should be using the recommended TIMESTAMP WITH TIME ZONE type
    OUTPUT
  end

  def test_timestamp_without_time_zone_with_precision_is_error
    Context.create_table(:events) do |t|
      t.column :occurred_at, "TIMESTAMP(6) WITHOUT TIME ZONE"
    end.define_model

    assert_problems(<<~OUTPUT)
      events.occurred_at should be using the recommended TIMESTAMP WITH TIME ZONE type
    OUTPUT
  end

  def test_timestamp_with_time_zone_is_ok
    Context.create_table(:events) do |t|
      t.column :occurred_at, "TIMESTAMP WITH TIME ZONE"
    end.define_model

    refute_problems
  end

  def test_config_ignore_tables
    Context.create_table(:events) do |t|
      t.column :occurred_at, "TIMESTAMP WITHOUT TIME ZONE"
    end.define_model

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :postgres_timestamps_without_time_zone,
          ignore_tables: ["events"]
      end
    CONFIG

    refute_problems
  end

  def test_config_ignore_columns
    Context.create_table(:events) do |t|
      t.column :occurred_at, "TIMESTAMP WITHOUT TIME ZONE"
    end.define_model

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :postgres_timestamps_without_time_zone,
          ignore_columns: ["events.occurred_at"]
      end
    CONFIG

    refute_problems
  end

  def test_global_ignore_tables
    Context.create_table(:events) do |t|
      t.column :occurred_at, "TIMESTAMP WITHOUT TIME ZONE"
    end.define_model

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.global :ignore_tables, ["events"]
      end
    CONFIG

    refute_problems
  end

  def test_incorrect_default_timestamp
    original_datetime_type = ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.datetime_type
    ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.datetime_type = :timestamp

    assert_problems(<<~OUTPUT)
      PostgreSQL default datetime type should be set to :timestamptz, not :timestamp
    OUTPUT
  ensure
    ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.datetime_type = original_datetime_type
  end

  def test_ignored_default_timestamp
    original_datetime_type = ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.datetime_type
    ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.datetime_type = :timestamp

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :postgres_timestamps_without_time_zone,
          ignore_datetime_type: true
      end
    CONFIG

    refute_problems
  ensure
    ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.datetime_type = original_datetime_type
  end
end
