# frozen_string_literal: true

require "active_record_doctor/printers"
require "active_record_doctor/printers/io_printer"
require "active_record_doctor/railtie" if defined?(Rails) && defined?(Rails::Railtie)
require "active_record_doctor/detectors"
require "active_record_doctor/detectors/base"
require "active_record_doctor/detectors/missing_presence_validation"
require "active_record_doctor/detectors/missing_foreign_keys"
require "active_record_doctor/detectors/missing_unique_indexes"
require "active_record_doctor/detectors/incorrect_boolean_presence_validation"
require "active_record_doctor/detectors/extraneous_indexes"
require "active_record_doctor/detectors/unindexed_deleted_at"
require "active_record_doctor/detectors/undefined_table_references"
require "active_record_doctor/detectors/missing_non_null_constraint"
require "active_record_doctor/detectors/unindexed_foreign_keys"
require "active_record_doctor/detectors/incorrect_dependent_option"
require "active_record_doctor/task"
require "active_record_doctor/version"

module ActiveRecordDoctor # :nodoc:
  def self.run
    results = tasks.map { |task| task.run }
    results.all?
  end

  def self.tasks
    Detectors.all.map do |detector_class|
      ActiveRecordDoctor::Task.new(detector_class)
    end
  end
end
