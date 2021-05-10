# frozen_string_literal: true

class ActiveRecordDoctor::Detectors::UndefinedTableReferencesTest < Minitest::Test
  def test_table_exists
    # No columns needed, just the table.
    create_table(:users)

    assert_equal([[], true], run_detector)
  end

  def test_table_does_not_exist
    create_model(:users)

    # We wrap the assertion in begin/ensure because we must recreate the
    # table as otherwise Temping will raise an error. Assertion errors are
    # signalled via exceptions which we shouldn't swallow if we don't want to
    # break the test suite hence the choice of begin/ensure.
    assert_equal([[["ModelFactory::Models::User", "users"]], true], run_detector)
  end

  def test_view_instead_of_table
    # We replace the underlying table with a view. The view doesn't have to be
    # backed by an actual table - it can simply return a predefined tuple.
    ActiveRecord::Base.connection.execute("CREATE VIEW users AS SELECT 1")
    create_model(:users)

    # We wrap the assertion in begin/ensure because we must recreate the
    # table as otherwise Temping will raise an error. Assertion errors are
    # signalled via exceptions which we shouldn't swallow if we don't want to
    # break the test suite hence the choice of begin/ensure.
    begin
      assert_equal([[], true], run_detector)
    ensure
      ActiveRecord::Base.connection.execute("DROP VIEW users")
    end
  end
end
