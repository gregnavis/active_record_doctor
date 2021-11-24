# frozen_string_literal: true

class ActiveRecordDoctor::RunnerTest < Minitest::Test
  def test_run_one_raises_on_unknown_detectors
    io = StringIO.new
    runner = ActiveRecordDoctor::Runner.new(load_config, io)

    assert_raises(KeyError) do
      runner.run_one(:performance_issues)
    end
  end

  def test_run_all_returns_true_when_no_errors
    io = StringIO.new
    runner = ActiveRecordDoctor::Runner.new(load_config, io)

    assert(runner.run_all)
    assert(io.string.blank?)
  end

  def test_run_all_returns_false_when_errors
    # Create a model without its underlying table to trigger an error.
    create_model(:User)

    io = StringIO.new
    runner = ActiveRecordDoctor::Runner.new(load_config, io)

    refute(runner.run_all)
    refute(io.string.blank?)
  end

  def test_help_prints_help
    ActiveRecordDoctor.detectors.each do |name, _|
      io = StringIO.new
      runner = ActiveRecordDoctor::Runner.new(load_config, io)

      runner.help(name)

      refute(io.string.blank?, "expected help for #{name}")
    end
  end
end
