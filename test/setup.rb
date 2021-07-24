# frozen_string_literal: true

# Configure Active Record.

# We must import "uri" explicitly as otherwsie URI won't be accessible in
# Ruby 2.7.2 / Rails 6.
require "uri"

require "active_record"
require "pg"
require "mysql2"

adapter = ENV.fetch("ADAPTER")
ActiveRecord::Base.establish_connection(adapter: adapter, database: "active_record_doctor_test")

puts "Using #{adapter}"

# We need to call #connection to enfore Active Record to actually establish
# the connection.
ActiveRecord::Base.connection

# We need to mock Rails because some detectors depend on .eager_load! This must
# happen AFTER loading active_record_doctor as otherwise it'd attempt to
# install a Railtie.
module Rails
  class TestApplication
    def eager_load!
    end
  end

  def self.application
    @application ||= TestApplication.new
  end
end

# Load Active Record Doctor.
require "active_record_doctor"

# Configure the test suite.
require "minitest"
require "minitest/autorun"
require "minitest/fork_executor"

require_relative "model_factory"

# Prepare the test class.
class Minitest::Test
  def setup
    # Ensure all remnants of previous test runs, most likely in form of tables,
    # are removed.
    ModelFactory.cleanup
  end

  def teardown
    ModelFactory.cleanup
  end

  private

  def postgresql?
    ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
  end

  def mysql?
    ActiveRecord::Base.connection.adapter_name == "Mysql2"
  end

  def create_table(*args, &block)
    ModelFactory.create_table(*args, &block)
  end

  def create_model(*args, &block)
    ModelFactory.create_model(*args, &block)
  end

  # Return the detector class under test.
  def detector_class
    self.class.name.sub(/Test$/, "").constantize
  end

  def run_task
    ActiveRecordDoctor::Task.new(detector_class).run
  end

  def assert_problems(expected_output)
    success = nil
    assert_output(expected_output) { success = run_task }
    refute(success)
  end

  def refute_problems
    success = nil
    assert_output("") { success = run_task }
    assert(success)
  end
end

# Filter out Minitest backtrace while allowing backtrace from other libraries
# to be shown.
Minitest.backtrace_filter = Minitest::BacktraceFilter.new

# Uncomment in case there's test case interference.
Minitest.parallel_executor = Minitest::ForkExecutor.new
