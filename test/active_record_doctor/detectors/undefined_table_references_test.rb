# frozen_string_literal: true

class ActiveRecordDoctor::Detectors::UndefinedTableReferencesTest < Minitest::Test
  def test_table_exists
    create_table(:users) do
    end.create_model do
    end

    refute_problems
  end

  def test_table_does_not_exist
    create_model(:users)

    assert_problems(<<OUTPUT)
The following models reference undefined tables:
  ModelFactory::Models::User (the table users is undefined)
OUTPUT
  end

  def test_view_instead_of_table
    # We replace the underlying table with a view. The view doesn't have to be
    # backed by an actual table - it can simply return a predefined tuple.
    ActiveRecord::Base.connection.execute("CREATE VIEW users AS SELECT 1")
    create_model(:users)

    begin
      refute_problems
    ensure
      ActiveRecord::Base.connection.execute("DROP VIEW users")
    end
  end
end
