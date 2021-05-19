# frozen_string_literal: true

class ActiveRecordDoctor::Detectors::UndefinedTableReferencesTest < Minitest::Test
  def test_table_exists
    create_table(:users) do
    end.create_model do
    end

    refute_problems
  end

  def test_table_does_not_exist_when_views_supported
    create_model(:users)

    if mysql? && ActiveRecord::VERSION::STRING < "5.0"
      assert_problems(<<OUTPUT)
WARNING: Models backed by database views are supported only in Rails 5+ OR
Rails 4.2 + PostgreSQL. It seems this is NOT your setup. Therefore, such models
will be erroneously reported below as not having their underlying tables/views.
Consider upgrading Rails or disabling this task temporarily.
The following models reference undefined tables:
  ModelFactory::Models::User (the table users is undefined)
OUTPUT
    else
      assert_problems(<<OUTPUT)
The following models reference undefined tables:
  ModelFactory::Models::User (the table users is undefined)
OUTPUT
    end
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
