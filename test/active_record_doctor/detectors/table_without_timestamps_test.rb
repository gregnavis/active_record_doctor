# frozen_string_literal: true

class ActiveRecordDoctor::Detectors::TableWithoutTimestampsTest < Minitest::Test
  def test_table_without_timestamps_reported
    Context.create_table(:companies) do |t|
      t.string :name
    end

    assert_problems(<<~OUTPUT)
      add a created_at column to companies
      add a updated_at column to companies
    OUTPUT
  end

  def test_table_with_timestamps_is_not_reported
    Context.create_table(:companies) do |t|
      t.timestamps
    end
    refute_problems
  end

  def test_table_with_alternative_timestamps_is_not_reported
    Context.create_table(:companies) do |t|
      t.timestamp :created_on
      t.timestamp :updated_on
    end
    refute_problems
  end

  def test_config_ignore_tables
    Context.create_table(:companies)

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :table_without_timestamps,
          ignore_tables: ["companies"]
      end
    CONFIG

    refute_problems
  end

  def test_global_ignore_tables
    Context.create_table(:companies)

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.global :ignore_tables, ["companies"]
      end
    CONFIG

    refute_problems
  end
end
