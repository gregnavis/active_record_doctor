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

namespace :active_record_doctor do
  detectors = ActiveRecordDoctor::Detectors.all

  detectors.each do |detector|
    desc detector.description
    task detector.underscored_name => :environment do
      detector.run or exit(1)
    end
  end

  desc "Run all active_record_doctor detectors"
  task :all => :environment do
    results = detectors.map(&:run)
    results.all? or exit(1)
  end
end
