# frozen_string_literal: true

class ActiveRecordDoctor::ConfigTest < Minitest::Test
  def test_config_absent
    assert_raises(ActiveRecordDoctor::Error::ConfigurationError) do
      load_config
    end
  end

  def test_config_not_called
    config_file("")

    assert_raises(ActiveRecordDoctor::Error::ConfigureNotCalled) do
      load_config
    end
  end

  def test_config_raises_exception
    config_file("1/0")

    assert_raises(ActiveRecordDoctor::Error::ConfigurationError) do
      load_config
    end
  end

  def test_config_called_twice
    config_file(<<CONFIG)
ActiveRecordDoctor.configure { |config| }
ActiveRecordDoctor.configure { |config| }
CONFIG

    assert_raises(ActiveRecordDoctor::Error::ConfigureCalledTwice) do
      load_config
    end
  end

  def test_init_called_twice
    config_file(<<CONFIG)
ActiveRecordDoctor.configure do |config|
  config.init do
  end
  config.init do
  end
end
CONFIG

    assert_raises(ActiveRecordDoctor::Error::InitConfiguredTwice) do
      load_config
    end
  end

  def test_detector_configured_twice
    config_file(<<CONFIG)
ActiveRecordDoctor.configure do |config|
  config.detector :extraneous_indexes, {}
  config.detector :extraneous_indexes, {}
end
CONFIG

    assert_raises(ActiveRecordDoctor::Error::DetectorConfiguredTwice) do
      load_config
    end
  end

  def test_unrecognized_detector_name
    config_file(<<CONFIG)
ActiveRecordDoctor.configure do |config|
  config.detector :other_performance_issues, {}
end
CONFIG

    assert_raises(ActiveRecordDoctor::Error::UnrecognizedDetectorName) do
      load_config
    end
  end

  def test_unrecognized_detector_setting
    config_file(<<CONFIG)
ActiveRecordDoctor.configure do |config|
  config.detector :extraneous_indexes, {
    delay: 1
  }
end
CONFIG

    assert_raises(ActiveRecordDoctor::Error::UnrecognizedDetectorSettings) do
      load_config
    end
  end

  def test_config_valid
    config_file(<<CONFIG)
ActiveRecordDoctor.configure do |config|
  config.detector :extraneous_indexes,
    ignore_tables: []
end
CONFIG

    config = load_config

    assert_nil(config.init)
    assert_equal(
      config.detectors,
      {
        extraneous_indexes: {
          ignore_tables: []
        }
      }
    )
  end

  private

  def load_config
    ActiveRecordDoctor.load_config(@config_path)
  end
end
