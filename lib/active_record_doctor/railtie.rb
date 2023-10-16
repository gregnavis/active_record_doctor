# frozen_string_literal: true

module ActiveRecordDoctor
  class Railtie < Rails::Railtie # :nodoc:
    rake_tasks do
      load "tasks/active_record_doctor.rake"
    end
  end
end
