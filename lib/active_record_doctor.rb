require "active_record_doctor/printers"
require "active_record_doctor/printers/io_printer"
require "active_record_doctor/railtie" if defined?(Rails) && defined?(Rails::Railtie)
require "active_record_doctor/tasks"
require "active_record_doctor/tasks/base"
require "active_record_doctor/tasks/missing_presence_validation"
require "active_record_doctor/tasks/missing_foreign_keys"
require "active_record_doctor/tasks/missing_unique_indexes"
require "active_record_doctor/tasks/incorrect_boolean_presence_validation"
require "active_record_doctor/tasks/extraneous_indexes"
require "active_record_doctor/tasks/unindexed_deleted_at"
require "active_record_doctor/tasks/undefined_table_references"
require "active_record_doctor/tasks/missing_non_null_constraint"
require "active_record_doctor/tasks/unindexed_foreign_keys"
require "active_record_doctor/version"

module ActiveRecordDoctor
end
