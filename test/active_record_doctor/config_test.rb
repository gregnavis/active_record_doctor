# frozen_string_literal: true

class ActiveRecordDoctor::ConfigTest < Minitest::Test
  def test_merge_globals_empty
    config1 = ActiveRecordDoctor::Config.new({}, {})
    config2 = ActiveRecordDoctor::Config.new({}, {})

    config = config1.merge(config2)

    assert_equal({}, config.globals)
  end

  def test_merge_globals_in_config1
    config1 = ActiveRecordDoctor::Config.new(
      { config1_global: "config1:config1_global" },
      {}
    )
    config2 = ActiveRecordDoctor::Config.new({}, {})

    config = config1.merge(config2)

    assert_equal(
      { config1_global: "config1:config1_global" },
      config.globals
    )
  end

  def test_merge_globals_in_config2
    config1 = ActiveRecordDoctor::Config.new({}, {})
    config2 = ActiveRecordDoctor::Config.new(
      { config2_global: "config2:config2_global" },
      {}
    )

    config = config1.merge(config2)

    assert_equal(
      { config2_global: "config2:config2_global" },
      config.globals
    )
  end

  def test_merge_globals_in_config1_and_config2
    config1 = ActiveRecordDoctor::Config.new(
      {
        config1_global: "config1:config1_global",
        shared_global: "config1:shared_global"
      },
      {}
    )
    config2 = ActiveRecordDoctor::Config.new(
      {
        config2_global: "config2:config2_global",
        shared_global: "config2:shared_global"
      },
      {}
    )

    config = config1.merge(config2)

    assert_equal(
      {
        config1_global: "config1:config1_global",
        shared_global: "config2:shared_global",
        config2_global: "config2:config2_global"
      },
      config.globals
    )
  end

  def test_merge_detectors
    config1 = ActiveRecordDoctor::Config.new(
      {},
      {
        config1_detector: {
          config1_setting: "config1:config1_detector.config1_setting"
        },
        shared_detector: {
          config1_setting: "config1:shared_detector.config1_setting",
          shared_setting: "config1:shared_detector.shared_setting"
        }
      }
    )
    config2 = ActiveRecordDoctor::Config.new(
      {},
      {
        config2_detector: {
          config2_setting: "config2:config2_detector.config2_setting"
        },
        shared_detector: {
          config2_setting: "config2:shared_detector.config2_setting",
          shared_setting: "config2:shared_detector.shared_setting"
        }
      }
    )

    config = config1.merge(config2)

    assert_equal(
      {
        config1_detector: {
          config1_setting: "config1:config1_detector.config1_setting"
        },
        config2_detector: {
          config2_setting: "config2:config2_detector.config2_setting"
        },
        shared_detector: {
          config1_setting: "config1:shared_detector.config1_setting",
          config2_setting: "config2:shared_detector.config2_setting",
          shared_setting: "config2:shared_detector.shared_setting"
        }
      },
      config.detectors
    )
  end
end
