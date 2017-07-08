require 'test_helper'

require 'active_record_doctor/tasks/undefined_table_references'

class ActiveRecordDoctor::Tasks::UndefinedTableReferencesTest < ActiveSupport::TestCase
  def test_undefined_table_references_are_reported
    result = run_task

    assert_equal([Contract], result)
  end

  private

  def run_task
    printer = SpyPrinter.new
    ActiveRecordDoctor::Tasks::UndefinedTableReferences.new(printer: printer).run
    printer.undefined_table_references
  end
end
