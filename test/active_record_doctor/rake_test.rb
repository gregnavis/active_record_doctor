require 'test_helper'

# Load all tasks
Dir["#{File.dirname(__FILE__)}/../../lib/active_record_doctor/tasks/*.rb"].each { |f| require f }

class ActiveRecordDoctor::RakeTest < ActiveSupport::TestCase
  def test_all_tasks_are_reported
    output = Dir.chdir(dummy_app_path) { `rake -T` }

    ActiveRecordDoctor::Tasks::Base.descendants.each do |task_class|
      name = task_class.name.demodulize.underscore.to_sym

      assert_includes(
        output,
        "active_record_doctor:#{name}",
        "rake -T should include #{name}"
      )
    end
  end
end
