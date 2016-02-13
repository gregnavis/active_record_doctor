module ActiveRecordDoctor
  class Railtie < Rails::Railtie
    rake_tasks do
      load "tasks/active_record_doctor_tasks.rake"
    end
  end
end
