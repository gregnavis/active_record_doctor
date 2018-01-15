require 'test_helper'

require 'active_record_doctor/tasks/unindexed_foreign_keys'
 
class ActiveRecordDoctor::Tasks::UnindexedForeignKeysTest < ActiveSupport::TestCase
  def test_unindexed_foreign_keys_are_reported
    result = run_task

    assert_equal({ "users" => ["profile_id"] }, result)
  end

  private

  def run_task
    ActiveRecordDoctor::Tasks::UnindexedForeignKeys.run.first
  end
end
