# frozen_string_literal: true

# Configure Active Record.

# We must import "uri" explicitly as otherwsie URI won't be accessible in
# Ruby 2.7.2 / Rails 6.
require "uri"

require "active_record"

# Connect to the database defined in the URL.
ActiveRecord::Base.establish_connection(ENV.fetch("DATABASE_URL"))

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

  # Run the appropriate detector. The detector name is inferred from the test class.
  def run_detector
    detector_class.run.first
  end

  def run_task
    output = StringIO.new
    printer = ActiveRecord::Printers::IOPrinter.new(output)
    success = ActiveRecordDoctor::Task.new(detector_class, printer).run
    [success, output.string]
  end

  # Assert results are equal without regards to the order of elements.
  def assert_result(expected_result)
    assert_equal(expected_result.sort_by(&:to_s), run_detector.sort_by(&:to_s))
  end
end

# Filter out Minitest backtrace while allowing backtrace from other libraries
# to be shown.
Minitest.backtrace_filter = Minitest::BacktraceFilter.new

# Run each test method in a separate process so that we avoid leaking
# temporary models defined by temping. I'm not entirely sure but it seems to
# be a problem with Rails caching those classes aggressively.
Minitest.parallel_executor = Minitest::ForkExecutor.new
