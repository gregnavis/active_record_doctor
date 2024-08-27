# frozen_string_literal: true

# Configure Active Record.

# We must import "uri" explicitly as otherwise URI won't be accessible in
# Ruby 2.7.2 / Rails 6.
require "uri"

require "active_record"
require "pg"
require "mysql2"

adapter = ENV.fetch("DATABASE_ADAPTER")
ActiveRecord::Base.configurations =
  if ActiveRecord::VERSION::MAJOR >= 6
    {
      "default_env" => {
        "primary" => {
          "adapter" => adapter,
          "host" => ENV.fetch("DATABASE_HOST", nil),
          "port" => ENV.fetch("DATABASE_PORT", nil),
          "username" => ENV.fetch("DATABASE_USERNAME", nil),
          "password" => ENV.fetch("DATABASE_PASSWORD", nil),
          "database" => "active_record_doctor_primary"
        },
        "secondary" => {
          "adapter" => adapter,
          "host" => ENV.fetch("DATABASE_HOST", nil),
          "port" => ENV.fetch("DATABASE_PORT", nil),
          "username" => ENV.fetch("DATABASE_USERNAME", nil),
          "password" => ENV.fetch("DATABASE_PASSWORD", nil),
          "database" => "active_record_doctor_secondary"
        }
      }
    }
  else
    {
      "primary" => {
        "adapter" => adapter,
        "host" => ENV.fetch("DATABASE_HOST", nil),
        "port" => ENV.fetch("DATABASE_PORT", nil),
        "username" => ENV.fetch("DATABASE_USERNAME", nil),
        "password" => ENV.fetch("DATABASE_PASSWORD", nil),
        "database" => "active_record_doctor_primary"
      }
    }
  end

puts "Using #{adapter}"

# Load Active Record Doctor.
require "active_record_doctor"

# Configure the test suite.
require "minitest"
require "minitest/autorun"
require "minitest/fork_executor"

require "transient_record"

# Filter out Minitest backtrace while allowing backtrace from other libraries
# to be shown.
Minitest.backtrace_filter = Minitest::BacktraceFilter.new

# Uncomment in case there's test case interference.
Minitest.parallel_executor = Minitest::ForkExecutor.new

# Set up Active Record models to mimic a real-world Active Record setup.
class ApplicationRecord < ActiveRecord::Base
  if ActiveRecord::VERSION::MAJOR >= 7
    primary_abstract_class
  else
    self.abstract_class = true
  end

  if ActiveRecord::VERSION::MAJOR >= 6
    connects_to database: { writing: :primary }
  end
end

ActiveRecord::Base.establish_connection :primary

# Transient Record contexts used by the test class below.
Context = TransientRecord.context_for ApplicationRecord

# Connect to another database when testing against a version that supports
# multiple databases.
if ActiveRecord::VERSION::MAJOR >= 6
  class SecondaryRecord < ApplicationRecord
    self.abstract_class = true

    if ActiveRecord::VERSION::MAJOR >= 6
      connects_to database: { writing: :secondary }
    end
  end

  SecondaryRecord.establish_connection :secondary

  SecondaryContext = TransientRecord.context_for SecondaryRecord
end

if ActiveRecord.version >= Gem::Version.new("7.1")
  # See https://github.com/rails/rails/pull/46522 for details.
  # When `false` (default in Rails 7.1) - validate presence only when the foreign key changed.
  # When `true` - always validate the association presence.
  ActiveRecord.belongs_to_required_validates_foreign_key = true
end

# Prepare the test class.
class Minitest::Test
  def setup
    # Delete remnants (models and tables) of previous test case runs.
    TransientRecord.cleanup
  end

  def teardown
    @config_path = nil

    if @previous_dir
      Dir.chdir(@previous_dir)
      @previous_dir = nil
    end

    # Ensure all remnants of previous test runs, most likely in form of tables,
    # are removed.
    TransientRecord.cleanup
  end

  private

  attr_reader :config_path

  def config_file(content)
    @previous_dir = Dir.pwd

    directory = Dir.mktmpdir("active_record_doctor")
    @config_path = File.join(directory, ".active_record_doctor.rb")
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
    runner = ActiveRecordDoctor::Runner.new(
      config: load_config,
      logger: ActiveRecordDoctor::Logger::Dummy.new,
      io: io
    )
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
    string.split("\n").sort
  end
end
