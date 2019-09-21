require "active_record_doctor/tasks"
require "active_record_doctor/tasks/unindexed_foreign_keys"
require "active_record_doctor/tasks/extraneous_indexes"
require "active_record_doctor/tasks/missing_foreign_keys"
require "active_record_doctor/tasks/undefined_table_references"
require "active_record_doctor/tasks/unindexed_deleted_at"
require "active_record_doctor/tasks/missing_unique_indexes"
require "active_record_doctor/tasks/missing_presence_validation"
require "active_record_doctor/tasks/missing_non_null_constraint"
require "active_record_doctor/tasks/incorrect_boolean_presence_validation"

namespace :active_record_doctor do
  def mount(task_class)
    name = task_class.name.demodulize.underscore.to_sym

    task name => :environment do
      result, success = task_class.run
      success = true if success.nil?

      printer = ActiveRecordDoctor::Printers::IOPrinter.new
      printer.public_send(name, result)

      # nil doesn't indicate a failure but rather no explicit result. We assume
      # success by default hence only false results in an erroneous exit code.
      exit(1) if success == false
    end
  end

  ActiveRecordDoctor::Tasks.all.each do |task|
    mount task
  end
end
