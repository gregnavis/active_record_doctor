require 'test_helper'

require 'active_record_doctor/tasks/unindexed_deleted_at'

class ActiveRecordDoctor::Tasks::UnindexedDeletedAtTest < ActiveSupport::TestCase
  def test_unindexed_deleted_at_are_reported
    result = run_task

    assert_equal(['index_profiles_on_first_name_and_last_name'], result)
  end

  private

  def run_task
    printer = SpyPrinter.new
    ActiveRecordDoctor::Tasks::UnindexedDeletedAt.new(printer: printer).run
    printer.unindexed_deleted_at
  end
end
