class ActiveSupport::TestCase
  private

  def run_task
    self.class.name.sub(/Test$/, '').constantize.run.first
  end

  def assert_result(expected_result)
    assert_equal(expected_result.sort_by(&:to_s), run_task.sort_by(&:to_s))
  end
end
