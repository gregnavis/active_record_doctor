require 'test_helper'

require 'active_record_doctor/tasks/extraneous_indexes'
 
class ActiveRecordDoctor::Tasks::ExtraneousIndexesTest < ActiveSupport::TestCase
  def test_extraneous_indexes_are_reported
    result = run_task

    assert_equal(
      result.sort,
      [
        ["index_users_on_last_name_and_first_name", "index_users_on_last_name_and_first_name_and_email"],
        ["index_users_on_last_name", "index_users_on_last_name_and_first_name_and_email"]
      ].sort
    )
  end

  private

  def run_task
    printer = SpyPrinter.new
    ActiveRecordDoctor::Tasks::ExtraneousIndexes.new(printer: printer).run
    printer.extraneous_indexes
  end
end
