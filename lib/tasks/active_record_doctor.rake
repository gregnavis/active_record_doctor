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
require "active_record_doctor/rake/task"

ActiveRecordDoctor::Rake::Task.new do |task|
  # This file is imported when active_record_doctor is being used as part of a
  # Rails app so it's the right place for all Rails-specific settings.
  task.deps = [:environment]
  task.config_path = Rails.root.join(".active_record_doctor")
  task.setup = -> { Rails.application.eager_load! }
end
