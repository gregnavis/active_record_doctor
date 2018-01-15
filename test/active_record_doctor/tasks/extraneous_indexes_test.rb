require 'test_helper'

require 'active_record_doctor/tasks/extraneous_indexes'
 
class ActiveRecordDoctor::Tasks::ExtraneousIndexesTest < ActiveSupport::TestCase
  def test_extraneous_indexes_are_reported
    result = run_task

    assert_equal(
      [
        ["index_employers_on_id", [:primary_key, "employers"]],
        ["index_users_on_last_name", [:multi_column, "index_users_on_last_name_and_first_name_and_email", "unique_index_on_users_last_name_and_first_name"]],
        ["index_users_on_last_name_and_first_name", [:multi_column, "index_users_on_last_name_and_first_name_and_email", "unique_index_on_users_last_name_and_first_name"]],
        ["index_users_on_email", [:multi_column, "unique_index_on_users_email"]],
      ].sort,
      result.sort
    )
  end

  private

  def run_task
    ActiveRecordDoctor::Tasks::ExtraneousIndexes.run.first
  end
end
