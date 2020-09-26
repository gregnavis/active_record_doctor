# Configure Active Record.
require "active_record"

# Connect to the database defined in the URL.
ActiveRecord::Base.establish_connection(ENV.fetch("DATABASE_URL"))

# We need to call #connection to enfore Active Record to actually establish
# the connection.
ActiveRecord::Base.connection



# We need to mock Rails because some tasks depend on .eager_load! This must
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



# temping is a test library for creating tables and models on the fly. We use
# it instead of a fixed dummy Rails app created by the generator.
require "temping"

# Temping 3.10.0 is broken because it removes the tables in the order of
# creation which fails if foreign key constraints are present.
class Temping
  class << self
    alias_method :old_teardown, :teardown

    def teardown
      @model_klasses.reverse!
      old_teardown

      # This hack is required to avoid leaking temporary model classes defined
      # by Temping. If we don't clear the cache then they'll be kept around and
      # returned as valid models which will break tests.
      ActiveSupport::DescendantsTracker.class_variable_get(:@@direct_descendants).clear
    end
  end
end



# Prepare the test class.
class Minitest::Test
  def teardown
    # Remove temporary databases created by the current test case.
    Temping.teardown
  end

  private

  # Run the appropriate task. The task name is inferred from the test class.
  def run_task
    self.class.name.sub(/Test$/, '').constantize.run.first
  end

  # Assert results are equal without regards to the order of elements.
  def assert_result(expected_result)
    assert_equal(expected_result.sort_by(&:to_s), run_task.sort_by(&:to_s))
  end
end

# Filter out Minitest backtrace while allowing backtrace from other libraries
# to be shown.
Minitest.backtrace_filter = Minitest::BacktraceFilter.new

# Run each test method in a separate process so that we avoid leaking
# temporary models defined by temping. I'm not entirely sure but it seems to
# be a problem with Rails caching those classes aggressively.
# Minitest.parallel_executor = Minitest::ForkExecutor.new
