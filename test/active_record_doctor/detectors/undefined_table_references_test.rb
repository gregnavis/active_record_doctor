# frozen_string_literal: true

class ActiveRecordDoctor::Detectors::UndefinedTableReferencesTest < Minitest::Test
  def test_model_backed_by_table
    create_table(:users) do
    end.create_model do
    end

    refute_problems
  end

  def test_model_backed_by_non_existent_table
    create_model(:User)

    assert_problems(<<~OUTPUT)
      ModelFactory::Models::User references a non-existent table or view named users
    OUTPUT
  end

  def test_model_backed_by_view
    # We replace the underlying table with a view. The view doesn't have to be
    # backed by an actual table - it can simply return a predefined tuple.
    ActiveRecord::Base.connection.execute("CREATE VIEW users AS SELECT 1")
    create_model(:User)

    begin
      refute_problems
    ensure
      ActiveRecord::Base.connection.execute("DROP VIEW users")
    end
  end

  def test_abstract_model
    create_model(:ApplicationRecord) do
      self.abstract_class = true
    end

    refute_problems
  end

  def test_config_ignore_tables
    create_model(:User)

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :undefined_table_references,
          ignore_models: ["ModelFactory::Models::User"]
      end
    CONFIG

    refute_problems
  end

  def test_global_ignore_tables
    create_model(:User)

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.global :ignore_models, ["ModelFactory::Models::User"]
      end
    CONFIG

    refute_problems
  end
end
