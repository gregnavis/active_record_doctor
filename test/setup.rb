# frozen_string_literal: true

# Configure Active Record.

# We must import "uri" explicitly as otherwise URI won't be accessible in
# Ruby 2.7.2 / Rails 6.
require "uri"

require "logger"
require "active_record"
require "pg"
require "mysql2"
require "sqlite3"

adapter = ENV.fetch("DATABASE_ADAPTER")

if adapter == "sqlite3"
  primary_database = secondary_database = ":memory:"
else
  primary_database = "active_record_doctor_primary"
  secondary_database = "active_record_doctor_secondary"
end

ActiveRecord::Base.configurations =
  {
    "default_env" => {
      "primary" => {
        "adapter" => adapter,
        "host" => ENV.fetch("DATABASE_HOST", nil),
        "port" => ENV.fetch("DATABASE_PORT", nil),
        "username" => ENV.fetch("DATABASE_USERNAME", nil),
        "password" => ENV.fetch("DATABASE_PASSWORD", nil),
        "database" => primary_database
      },
      "secondary" => {
        "adapter" => adapter,
        "host" => ENV.fetch("DATABASE_HOST", nil),
        "port" => ENV.fetch("DATABASE_PORT", nil),
        "username" => ENV.fetch("DATABASE_USERNAME", nil),
        "password" => ENV.fetch("DATABASE_PASSWORD", nil),
        "database" => secondary_database
      }
    }
  }

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

  connects_to database: { writing: :primary }
end

ActiveRecord::Base.establish_connection :primary

# Enable pgcrypto extension for PostgreSQL if needed (for gen_random_uuid)
if adapter == "postgresql"
  ActiveRecord::Base.connection.execute("CREATE EXTENSION IF NOT EXISTS pgcrypto;")
end

# Transient Record contexts used by the test class below.
Context = TransientRecord.context_for ApplicationRecord

# Connect to another database.
class SecondaryRecord < ApplicationRecord
  self.abstract_class = true

  connects_to database: { writing: :secondary }
end

SecondaryRecord.establish_connection :secondary

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

  def require_partial_indexes!
    skip("#{current_adapter} doesn't support partial indexes") if !postgresql?
  end

  def require_operator_classes!
    skip("#{current_adapter} doesn't support operator classes") if !postgresql?
  end

  def require_materialized_views!
    skip("#{current_adapter} doesn't support materialized views") if !postgresql?
  end

  def require_non_key_index_columns!
    skip("Active Record < 7.1 doesn't support non-key index columns") if ActiveRecord::VERSION::STRING < "7.1"
    skip("#{current_adapter} doesn't support non-key index columns") if !postgresql?
  end

  def require_expression_indexes!
    skip("#{current_adapter} doesn't support expression indexes") if ActiveRecord::Base.connection.supports_expression_index?
  end

  def require_non_indexed_foreign_keys!
    skip("#{current_adapter} doesn't support unindexed foreign keys") if mysql?
  end

  def require_citext!
    skip("#{current_adapter} doesn't support CITEXT column type") if !postgresql?
  end

  def require_arbitrary_long_text_columns!
    skip("#{current_adapter} doesn't support text columns of arbitrary length") if mysql?
  end

  def require_uuid_column_type!
    skip("#{current_adapter} doesn't support UUID column types") if !postgresql?
  end

  def require_optimized_association_presence_validations!
    skip("ActiveRecord < 7.1 doesn't support optimized association presence validation") if ActiveRecord::VERSION::STRING < "7.1"
  end

  def require_additional_index_types!
    skip("#{current_adapter} doesn't support additional index types") if sqlite?
  end

  def require_foreign_keys_of_different_type!
    skip("#{current_adapter} doesn't support foreign keys of different type than the referenced column") if mysql?
  end

  def current_adapter
    ActiveRecord::Base.connection.adapter_name
  end

  def postgresql?
    current_adapter == "PostgreSQL"
  end

  def mysql?
    current_adapter == "Mysql2"
  end

  def sqlite?
    current_adapter == "SQLite"
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
