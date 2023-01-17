# frozen_string_literal: true

class ActiveRecordDoctor::Detectors::DisableTest < Minitest::Test
  # Disabling detectors is implemented in the base class. It's enought to test
  # it on a single detector to be reasonably certain it works on all of them.
  def test_disabling
    create_table(:users) do |t|
      t.string :name, null: true
    end.define_model do
      validates :name, presence: true
    end

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :missing_non_null_constraint,
          enabled: false
      end
    CONFIG

    refute_problems
  end

  private

  # We need to override that method in order to skip the mechanism that
  # infers detector name from the test class name.
  def detector_name
    :missing_non_null_constraint
  end
end
