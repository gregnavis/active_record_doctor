# frozen_string_literal: true

class ActiveRecordDoctor::Detectors::TableWithoutPrimaryKeyTest < Minitest::Test
  def test_table_without_primary_key_reported
    Context.create_table(:companies, id: false) do |t|
      t.string :name
    end

    assert_problems(<<~OUTPUT)
      add a primary key to companies
    OUTPUT
  end

  def test_table_with_primary_key_is_not_reported
    Context.create_table(:companies)
    refute_problems
  end

  def test_config_ignore_tables
    Context.create_table(:companies, id: false) do |t|
      t.string :name
    end

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :table_without_primary_key,
          ignore_tables: ["companies"]
      end
    CONFIG

    refute_problems
  end

  def test_global_ignore_tables
    Context.create_table(:companies, id: false) do |t|
      t.string :name
    end

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.global :ignore_tables, ["companies"]
      end
    CONFIG

    refute_problems
  end
end
