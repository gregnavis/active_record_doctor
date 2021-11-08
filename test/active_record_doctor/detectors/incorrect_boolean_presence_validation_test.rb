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

    assert_problems(<<~OUTPUT)
      replace the `presence` validator on ModelFactory::Models::User.active with `inclusion` - `presence` can't be used on booleans
    OUTPUT
  end

  def test_inclusion_is_not_reported
    create_table(:users) do |t|
      t.boolean :active, null: false
    end.create_model do
      validates :active, inclusion: { in: [true, false] }
    end

    refute_problems
  end

  def test_models_with_non_existent_tables_are_skipped
    create_model(:users)

    refute_problems
  end

  def test_config_ignore_models
    create_table(:users) do |t|
      t.string :email, null: false
    end.create_model

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :incorrect_boolean_presence_validation,
          ignore_models: ["ModelFactory.User"]
      end
    CONFIG

    refute_problems
  end

  def test_global_ignore_models
    create_table(:users) do |t|
      t.string :email, null: false
    end.create_model

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.global :ignore_models, ["ModelFactory.User"]
      end
    CONFIG

    refute_problems
  end

  def test_config_ignore_attributes
    create_table(:users) do |t|
      t.string :email, null: false
    end.create_model

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :incorrect_boolean_presence_validation,
          ignore_attributes: ["ModelFactory.User.email"]
      end
    CONFIG

    refute_problems
  end
end
