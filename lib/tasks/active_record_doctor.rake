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

namespace :active_record_doctor do
  def mount(detector_class)
    name = detector_class.name.demodulize.underscore.to_sym

    desc detector_class.description
    task name => :environment do
      result, success = detector_class.run
      success = true if success.nil?

      printer = ActiveRecordDoctor::Printers::IOPrinter.new
      printer.public_send(name, result)

      # nil doesn't indicate a failure but rather no explicit result. We assume
      # success by default hence only false results in an erroneous exit code.
      exit(1) if success == false
    end
  end

  ActiveRecordDoctor::Detectors.all.each do |detector|
    mount detector
  end
end
