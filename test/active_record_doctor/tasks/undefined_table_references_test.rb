require 'test_helper'

require 'active_record_doctor/tasks/undefined_table_references'

class ActiveRecordDoctor::Tasks::UndefinedTableReferencesTest < ActiveSupport::TestCase
  def test_table_exists
    # No columns needed, just the table.
    Temping.create(:users, temporary: false)

    assert_equal([[], true], run_task)
  end

  def test_table_does_not_exist
    # No columns needed, just the table.
    Temping.create(:users, temporary: false)

    # We drop the underlying table to make the model invalid.
    ActiveRecord::Base.connection.drop_table(User.table_name)

    # We wrap the assertion in begin/ensure because we must recreate the
    # table as otherwise Temping will raise an error. Assertion errors are
    # signalled via exceptions which we shouldn't swallow if we don't want to
    # break the test suite hence the choice of begin/ensure.
    begin
      assert_equal([[[User.name, User.table_name]], true], run_task)
    ensure
      ActiveRecord::Base.connection.create_table(User.table_name)
    end
  end

  def test_view_instead_of_table
    # No columns needed, just the table.
    Temping.create(:users, temporary: false)

    # We replace the underlying table with a view. The view doesn't have to be
    # backed by an actual table - it can simply return a predefined tuple.
    ActiveRecord::Base.connection.drop_table(User.table_name)
    ActiveRecord::Base.connection.execute("CREATE VIEW users AS SELECT 1")

    # We wrap the assertion in begin/ensure because we must recreate the
    # table as otherwise Temping will raise an error. Assertion errors are
    # signalled via exceptions which we shouldn't swallow if we don't want to
    # break the test suite hence the choice of begin/ensure.
    begin
      assert_equal([[], true], run_task)
    ensure
      ActiveRecord::Base.connection.execute("DROP VIEW users")
      ActiveRecord::Base.connection.create_table(User.table_name)
    end
  end
end
