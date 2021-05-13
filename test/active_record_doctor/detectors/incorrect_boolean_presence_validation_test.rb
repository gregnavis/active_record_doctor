# frozen_string_literal: true

class ActiveRecordDoctor::Detectors::IncorrectBooleanPresenceValidationTest < Minitest::Test
  def test_presence_true_is_reported_on_boolean_only
    create_table(:users) do |t|
      t.string :email, null: false
      t.boolean :active, null: false
    end.create_model do
      # email is a non-boolean column whose presence CAN be validated in the
      # usual way. We include it in the test model to ensure the detector reports
      # only boolean columns.
      validates :email, :active, presence: true
    end

    assert_success(<<OUTPUT)
The presence of the following boolean columns is validated incorrectly:
  ModelFactory::Models::User: active
OUTPUT
  end

  def test_inclusion_is_not_reported
    create_table(:users) do |t|
      t.boolean :active, null: false
    end.create_model do
      validates :active, inclusion: { in: [true, false] }
    end

    assert_success("")
  end

  def test_models_with_non_existent_tables_are_skipped
    create_model(:users)

    assert_success("")
  end
end
