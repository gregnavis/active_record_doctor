class ActiveRecordDoctor::Tasks::IncorrectBooleanPresenceValidationTest < Minitest::Test
  def test_presence_true_is_reported_on_boolean_only
    create_table(:users) do |t|
      t.string :email, null: false
      t.boolean :active, null: false
    end.create_model do
      # email is a non-boolean column whose presence CAN be validated in the
      # usual way. We include it in the test model to ensure the task reports
      # only boolean columns.
      validates :email, :active, presence: true
    end

    assert_equal({ 'ModelFactory::Models::User' => ['active'] }, run_task)
  end

  def test_inclusion_is_not_reported
    create_table(:users) do |t|
      t.boolean :active, null: false
    end.create_model do
      validates :active, inclusion: { in: [true, false] }
    end

    assert_equal({}, run_task)
  end

  def test_models_with_non_existent_tables_are_skipped
    create_model(:users)

    # No need to assert anything as merely not raising an exception is a success.
    run_task
  end
end
