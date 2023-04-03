# frozen_string_literal: true

require "active_record_doctor/railtie" if defined?(Rails) && defined?(Rails::Railtie)
require "active_record_doctor/utils"
require "active_record_doctor/logger"
require "active_record_doctor/logger/dummy"
require "active_record_doctor/logger/hierarchical"
require "active_record_doctor/detectors"
require "active_record_doctor/detectors/base"
require "active_record_doctor/detectors/missing_presence_validation"
require "active_record_doctor/detectors/missing_foreign_keys"
require "active_record_doctor/detectors/missing_unique_indexes"
require "active_record_doctor/detectors/incorrect_boolean_presence_validation"
require "active_record_doctor/detectors/incorrect_length_validation"
require "active_record_doctor/detectors/extraneous_indexes"
require "active_record_doctor/detectors/unindexed_deleted_at"
require "active_record_doctor/detectors/undefined_table_references"
require "active_record_doctor/detectors/missing_non_null_constraint"
require "active_record_doctor/detectors/unindexed_foreign_keys"
require "active_record_doctor/detectors/incorrect_dependent_option"
require "active_record_doctor/detectors/short_primary_key_type"
require "active_record_doctor/detectors/mismatched_foreign_key_type"
require "active_record_doctor/errors"
require "active_record_doctor/help"
require "active_record_doctor/runner"
require "active_record_doctor/version"
require "active_record_doctor/config"
require "active_record_doctor/config/loader"

module ActiveRecordDoctor # :nodoc:
end
