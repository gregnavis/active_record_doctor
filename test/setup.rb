# frozen_string_literal: true

# Configure Active Record.

# We must import "uri" explicitly as otherwsie URI won't be accessible in
# Ruby 2.7.2 / Rails 6.
require "uri"

require "active_record"
require "pg"
require "mysql2"

adapter = ENV.fetch("DATABASE_ADAPTER")
ActiveRecord::Base.establish_connection(
  adapter: adapter,
  host: ENV["DATABASE_HOST"],
  port: ENV["DATABASE_PORT"],
  username: ENV["DATABASE_USERNAME"],
  password: ENV["DATABASE_PASSWORD"],
  database: "active_record_doctor_test"
)

puts "Using #{adapter}"

# We need to call #connection to enfore Active Record to actually establish
# the connection.
ActiveRecord::Base.connection

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
    @config_path = nil

    if @previous_dir
      Dir.chdir(@previous_dir)
      @previous_dir = nil
    end

    ModelFactory.cleanup
  end

  private

  attr_reader :config_path

  def config_file(content)
    @previous_dir = Dir.pwd

    directory = Dir.mktmpdir("active_record_doctor")
    @config_path = File.join(directory, ".active_record_doctor")
    File.write(@config_path, content)
    Dir.chdir(directory)
  end

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

  def detector
    self.class.name.sub(/Test$/, "").constantize
  end

  def runner
    config =
      if @config_path
        ActiveRecordDoctor.load_config(@config_path)
      else
        ActiveRecordDoctor::Config.new(nil, {})
      end

    ActiveRecordDoctor::Runner.new(config)
  end

  def assert_problems(expected_output)
    success = nil
    assert_output(expected_output) { success = runner.run(detector) }
    refute(success)
  end

  def refute_problems(expected_output = "")
    success = nil
    assert_output(expected_output) { success = runner.run(detector) }
    assert(success)
  end
end

# Filter out Minitest backtrace while allowing backtrace from other libraries
# to be shown.
Minitest.backtrace_filter = Minitest::BacktraceFilter.new

# Uncomment in case there's test case interference.
Minitest.parallel_executor = Minitest::ForkExecutor.new
