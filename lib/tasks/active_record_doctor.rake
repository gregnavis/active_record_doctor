# frozen_string_literal: true

require "active_record_doctor/detectors"
require "active_record_doctor/detectors/unindexed_foreign_keys"
require "active_record_doctor/detectors/extraneous_indexes"
require "active_record_doctor/detectors/missing_foreign_keys"
require "active_record_doctor/detectors/undefined_table_references"
require "active_record_doctor/detectors/unindexed_deleted_at"
require "active_record_doctor/detectors/missing_unique_indexes"
require "active_record_doctor/detectors/missing_presence_validation"
require "active_record_doctor/detectors/missing_non_null_constraint"
require "active_record_doctor/detectors/incorrect_boolean_presence_validation"
require "active_record_doctor/task"

namespace :active_record_doctor do
  def mount(detector_class)
    task = ActiveRecordDoctor::Task.new(detector_class)

    desc task.description
    task task.name => :environment do
      success = task.run
      exit(1) unless success
    end
  end

  ActiveRecordDoctor::Detectors.all.each do |detector|
    mount detector
  end
end
