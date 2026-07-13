# frozen_string_literal: true

class ActiveRecordDoctor::Detectors::UndefinedModelReferencesTest < Minitest::Test
  def test_table_with_model
    Context.create_table(:users) do
    end.define_model do
    end

    refute_problems
  end

  def test_table_without_model
    Context.create_table(:users) do
    end

    assert_problems(<<~OUTPUT)
      The users table is not referenced by a Rails model. If you are in the process of migrating it away, temporarily ignore it by adding it to the `ignore_tables` configuration and then remove it after the ruby code no longer uses it. Remember, do not delete the table until your deployed application code no longer uses it.
    OUTPUT
  end

  def test_config_ignore_tables
    Context.create_table(:users) do
    end

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :undefined_model_references,
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
        config.global :ignore_tables, ["users"]
      end
    CONFIG

    refute_problems
  end
end
