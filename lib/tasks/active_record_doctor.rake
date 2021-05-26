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
require "active_record_doctor/detectors/incorrect_dependent_option"
require "active_record_doctor/detectors/short_primary_key_type"
require "active_record_doctor/detectors/mismatched_foreign_key_type"
require "active_record_doctor/task"

namespace :active_record_doctor do
  tasks = ActiveRecordDoctor::Detectors.all.map do |detector_class|
    ActiveRecordDoctor::Task.new(detector_class)
  end

  tasks.each do |task|
    desc task.description
    task task.name => :environment do
      task.run or exit(1)
    end
  end

  desc "Run all active_record_doctor tasks"
  task :all => :environment do
    results = tasks.map { |task| task.run }
    results.all? or exit(1)
  end
end
