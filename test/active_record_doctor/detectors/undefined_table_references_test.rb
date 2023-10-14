# frozen_string_literal: true

class ActiveRecordDoctor::Detectors::UndefinedTableReferencesTest < Minitest::Test
  def test_model_backed_by_table
    Context.create_table(:users) do
    end.define_model do
    end

    refute_problems
  end

  def test_model_backed_by_non_existent_table
    Context.define_model(:User)

    assert_problems(<<~OUTPUT)
      Context::User references a non-existent table or view named users
    OUTPUT
  end

  def test_model_backed_by_view
    # We replace the underlying table with a view. The view doesn't have to be
    # backed by an actual table - it can simply return a predefined tuple.
    ActiveRecord::Base.connection.execute("CREATE VIEW users AS SELECT 1")
    Context.define_model(:User)

    refute_problems
  ensure
    ActiveRecord::Base.connection.execute("DROP VIEW users")
  end

  def test_config_ignore_tables
    Context.define_model(:User)

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :undefined_table_references,
          ignore_models: ["Context::User"]
      end
    CONFIG

    refute_problems
  end

  def test_global_ignore_tables
    Context.define_model(:User)

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.global :ignore_models, ["Context::User"]
      end
    CONFIG

    refute_problems
  end
end
