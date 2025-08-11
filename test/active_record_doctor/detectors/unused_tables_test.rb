# frozen_string_literal: true

class ActiveRecordDoctor::Detectors::UnusedTablesTest < Minitest::Test
  def test_disabled_by_default
    Context.create_table(:users) do
    end

    refute_problems
  end

  def test_table_with_model
    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :unused_tables, enabled: true
      end
    CONFIG

    Context.create_table(:users) do
    end.define_model do
    end

    refute_problems
  end

  def test_table_without_model
    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :unused_tables, enabled: true
      end
    CONFIG

    Context.create_table(:users) do
    end

    assert_problems(<<~OUTPUT)
      The users table is not referenced by any Rails model and can be dropped
    OUTPUT
  end

  def test_config_ignore_tables
    Context.create_table(:users) do
    end

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :unused_tables,
          enabled: true,
          ignore_tables: ["users"]
      end
    CONFIG

    refute_problems
  end

  def test_global_ignore_tables
    Context.create_table(:users) do
    end

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :unused_tables, enabled: true
        config.global :ignore_tables, ["users"]
      end
    CONFIG

    refute_problems
  end
end
