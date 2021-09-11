# frozen_string_literal: true

class ActiveRecordDoctor::Detectors::UndefinedTableReferencesTest < Minitest::Test
  def test_table_exists_when_views_supported
    skip unless views_supported?

    create_table(:users) do
    end.create_model do
    end

    refute_problems
  end

  def test_table_exists_when_views_not_supported
    skip if views_supported?

    create_table(:users) do
    end.create_model do
    end

    refute_problems(<<OUTPUT)
WARNING: Models backed by database views are supported only in Rails 5+ OR
Rails 4.2 + PostgreSQL. It seems this is NOT your setup. Therefore, such models
will be erroneously reported below as not having their underlying tables/views.
Consider upgrading Rails or skipping invalid warnings reported below.
OUTPUT
  end

  def test_warning_when_views_not_supported
    skip if views_supported?

    create_model(:users)

    assert_problems(<<OUTPUT)
WARNING: Models backed by database views are supported only in Rails 5+ OR
Rails 4.2 + PostgreSQL. It seems this is NOT your setup. Therefore, such models
will be erroneously reported below as not having their underlying tables/views.
Consider upgrading Rails or skipping invalid warnings reported below.
ModelFactory::Models::User references a non-existent table or view named users
OUTPUT
  end

  def test_no_warning_when_views_supported
    skip unless views_supported?

    create_model(:users)

    assert_problems(<<OUTPUT)
ModelFactory::Models::User references a non-existent table or view named users
OUTPUT
  end

  def test_view_instead_of_table
    skip unless views_supported?

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

  private

  def views_supported?
    !mysql? || ActiveRecord::VERSION::STRING >= "5.0"
  end
end
