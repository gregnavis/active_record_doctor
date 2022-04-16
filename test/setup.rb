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

# Filter out Minitest backtrace while allowing backtrace from other libraries
# to be shown.
Minitest.backtrace_filter = Minitest::BacktraceFilter.new

# Uncomment in case there's test case interference.
Minitest.parallel_executor = Minitest::ForkExecutor.new

# Prepare the test class.
class Minitest::Test
  include ModelFactory

  def setup
    # Delete remnants (models and tables) of previous test case runs.
    cleanup_models
  end

  def teardown
    @config_path = nil

    if @previous_dir
      Dir.chdir(@previous_dir)
      @previous_dir = nil
    end

    # Ensure all remnants of previous test runs, most likely in form of tables,
    # are removed.
    cleanup_models
  end

  private

  attr_reader :config_path

  def config_file(content)
    @previous_dir = Dir.pwd

    directory = Dir.mktmpdir("active_record_doctor")
    @config_path = File.join(directory, ".active_record_doctor")
    File.write(@config_path, content)
    Dir.chdir(directory)

    @config_path
  end

  def postgresql?
    ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
  end

  def mysql?
    ActiveRecord::Base.connection.adapter_name == "Mysql2"
  end

  def detector_name
    self.class.name.sub(/Test$/, "").demodulize.underscore.to_sym
  end

  def run_detector
    io = StringIO.new
    runner = ActiveRecordDoctor::Runner.new(load_config, io)
    success = runner.run_one(detector_name)
    [success, io.string]
  end

  def load_config
    ActiveRecordDoctor.load_config_with_defaults(@config_path)
  end

  def assert_problems(expected_output)
    success, output = run_detector
    assert_equal(sort_lines(expected_output), sort_lines(output))
    refute(success, "Expected the detector to return failure.")
  end

  def refute_problems(expected_output = "")
    success, output = run_detector
    assert_equal(sort_lines(expected_output), sort_lines(output))
    assert(success, "Expected the detector to return success.")
  end

  def sort_lines(string)
    string.split("\n").sort.join("\n")
  end
end
