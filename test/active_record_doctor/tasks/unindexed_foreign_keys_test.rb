require 'test_helper'

require 'active_record_doctor/tasks/unindexed_foreign_keys'
 
class ActiveRecordDoctor::Tasks::UnindexedForeignKeysTest < ActiveSupport::TestCase
  def test_unindexed_foreign_keys_are_reported
    result = run_task

    assert_equal([{ "users" => ["profile_id"] }], result)
  end

  private

  def run_task
    printer = SpyPrinter.new
    ActiveRecordDoctor::Tasks::UnindexedForeignKeys.new(printer: printer).run
    printer.unindexed_foreign_keys
  end
end
