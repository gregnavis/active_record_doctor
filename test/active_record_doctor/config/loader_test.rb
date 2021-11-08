# frozen_string_literal: true

class ActiveRecordDoctor::LoaderTest < Minitest::Test
  def test_load_config
    config_path = config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.global :ignore_tables, ["schema_migrations"]

        config.detector :extraneous_indexes, ignore_tables: ["users"]
      end
    CONFIG

    config = ActiveRecordDoctor.load_config(config_path)

    assert_equal(
      { ignore_tables: ["schema_migrations"] },
      config.globals
    )
    assert_equal(
      { extraneous_indexes: { ignore_tables: ["users"] } },
      config.detectors
    )
  end

  def test_load_config_raises_when_configuration_file_missing
    exc = assert_raises(ActiveRecordDoctor::Error::ConfigurationFileMissing) do
      ActiveRecordDoctor.load_config("/tmp/config.rb")
    end
    assert_equal("/tmp/config.rb", exc.config_path)
  end

  def test_load_config_raises_when_configuration_file_raises
    config_path = config_file("1/0")

    assert_raises(ActiveRecordDoctor::Error::ConfigurationError) do
      ActiveRecordDoctor.load_config(config_path)
    end
  end

  def test_load_config_raises_when_configure_not_called
    config_path = config_file("# configure is not called")

    assert_raises(ActiveRecordDoctor::Error::ConfigureNotCalled) do
      ActiveRecordDoctor.load_config(config_path)
    end
  end

  def test_load_config_raises_when_configure_called_twice
    config_path = config_file(<<-CONFIG)
      ActiveRecordDoctor.configure { |config| }
      ActiveRecordDoctor.configure { |config| }
    CONFIG

    assert_raises(ActiveRecordDoctor::Error::ConfigureCalledTwice) do
      ActiveRecordDoctor.load_config(config_path)
    end
  end

  def test_load_config_raises_when_unrecognized_global_set
    config_path = config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.global :user, "acme"
      end
    CONFIG

    assert_raises(ActiveRecordDoctor::Error::UnrecognizedGlobalSetting) do
      ActiveRecordDoctor.load_config(config_path)
    end
  end

  def test_load_config_raises_when_global_set_twice
    config_path = config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.global :ignore_tables, ["schema_migrations"]
        config.global :ignore_tables, ["schema_migrations"]
      end
    CONFIG

    assert_raises(ActiveRecordDoctor::Error::DuplicateGlobalSetting) do
      ActiveRecordDoctor.load_config(config_path)
    end
  end

  def test_load_config_raises_when_configured_unrecognized_detector
    config_path = config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :other_performance_issues, {}
      end
    CONFIG

    assert_raises(ActiveRecordDoctor::Error::UnrecognizedDetectorName) do
      ActiveRecordDoctor.load_config(config_path)
    end
  end

  def test_load_config_raises_when_detector_configured_twice
    config_path = config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :extraneous_indexes, ignore_tables: ["users"]
        config.detector :extraneous_indexes, ignore_tables: ["users"]
      end
    CONFIG

    assert_raises(ActiveRecordDoctor::Error::DetectorConfiguredTwice) do
      ActiveRecordDoctor.load_config(config_path)
    end
  end

  def test_load_config_raises_when_provided_unrecognized_detector_setting
    config_path = config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :extraneous_indexes, { delay: 1 }
      end
    CONFIG

    assert_raises(ActiveRecordDoctor::Error::UnrecognizedDetectorSettings) do
      ActiveRecordDoctor.load_config(config_path)
    end
  end
end
