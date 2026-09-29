# frozen_string_literal: true

class ActiveRecordDoctor::RunnerTest < Minitest::Test
  def setup
    @io = StringIO.new
    connection = ActiveRecord::Base.connection
    schema_inspector = ActiveRecordDoctor::CachingSchemaInspector.new(connection)

    @runner = ActiveRecordDoctor::Runner.new(
      config: load_config,
      logger: ActiveRecordDoctor::Logger::Dummy.new,
      io: @io,
      schema_inspector: schema_inspector
    )
  end

  def test_run_one_raises_on_unknown_detectors
    assert_raises(KeyError) do
      @runner.run_one(:performance_issues)
    end
  end

  def test_run_all_returns_true_when_no_errors
    assert(@runner.run_all)
    assert(@io.string.blank?)
  end

  def test_run_all_returns_false_when_errors
    # Create a model without its underlying table to trigger an error.
    Context.define_model(:User)

    refute(@runner.run_all)
    refute(@io.string.blank?)
  end

  def test_help_prints_help
    ActiveRecordDoctor.detectors.each_key do |name|
      @io.truncate(0)

      @runner.help(name)

      refute(@io.string.blank?, "expected help for #{name}")
    end
  end
end
