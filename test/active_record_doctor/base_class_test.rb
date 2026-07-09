# frozen_string_literal: true

class ActiveRecordDoctor::BaseClassTest < Minitest::Test
  def setup
    @config = ActiveRecordDoctor.load_config_with_defaults(nil)
    @logger = ActiveRecordDoctor::Logger::Dummy.new
    @io = StringIO.new
  end

  def test_runner_defaults_base_class_to_active_record_base
    runner = ActiveRecordDoctor::Runner.new(config: @config, logger: @logger, io: @io)

    assert_equal(ActiveRecord::Base, runner.send(:base_class))
  end

  def test_runner_accepts_custom_base_class
    runner = ActiveRecordDoctor::Runner.new(
      config: @config,
      logger: @logger,
      base_class: ApplicationRecord,
      io: @io
    )

    assert_equal(ApplicationRecord, runner.send(:base_class))
  end

  def test_detector_models_are_scoped_to_base_class
    # Anonymous classes avoid polluting the global detector suite; tie to an
    # existing table so other detectors are not affected by random test order.
    isolated_root = Class.new(ActiveRecord::Base) do
      self.abstract_class = true
    end
    isolated_leaf = Class.new(isolated_root) do
      self.table_name = "schema_migrations"
    end

    detector = ActiveRecordDoctor::Detectors::MissingForeignKeys.new(
      config: @config,
      logger: @logger,
      base_class: isolated_root,
      io: @io
    )

    assert_includes(detector.send(:models), isolated_leaf)
    refute_includes(detector.send(:models), ApplicationRecord)
  end

  def test_detector_connection_follows_base_class
    primary = ActiveRecordDoctor::Detectors::MissingForeignKeys.new(
      config: @config,
      logger: @logger,
      base_class: ApplicationRecord,
      io: @io
    )

    secondary = ActiveRecordDoctor::Detectors::MissingForeignKeys.new(
      config: @config,
      logger: @logger,
      base_class: SecondaryRecord,
      io: @io
    )

    assert_equal(ApplicationRecord.connection, primary.send(:connection))
    assert_equal(SecondaryRecord.connection, secondary.send(:connection))
  end

  def test_rake_task_resolves_base_class_from_environment
    previous = ENV.fetch("ACTIVE_RECORD_DOCTOR_BASE_CLASS", nil)
    ENV["ACTIVE_RECORD_DOCTOR_BASE_CLASS"] = "ApplicationRecord"

    task = ActiveRecordDoctor::Rake::Task.new { |t| t.deps = [] }

    assert_equal(ApplicationRecord, task.send(:base_class))
  ensure
    restore_env("ACTIVE_RECORD_DOCTOR_BASE_CLASS", previous)
  end

  def test_rake_task_defaults_base_class_to_active_record_base
    previous = ENV.fetch("ACTIVE_RECORD_DOCTOR_BASE_CLASS", nil)
    ENV.delete("ACTIVE_RECORD_DOCTOR_BASE_CLASS")

    task = ActiveRecordDoctor::Rake::Task.new { |t| t.deps = [] }

    assert_equal(ActiveRecord::Base, task.send(:base_class))
  ensure
    restore_env("ACTIVE_RECORD_DOCTOR_BASE_CLASS", previous)
  end

  private

  def restore_env(key, previous)
    if previous
      ENV[key] = previous
    else
      ENV.delete(key)
    end
  end
end
