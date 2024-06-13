# frozen_string_literal: true

class ActiveRecordDoctor::Detectors::IncorrectBooleanPresenceValidationTest < Minitest::Test
  def test_presence_true_is_reported_on_boolean_only
    Context.create_table(:users) do |t|
      t.string :email, null: false
      t.boolean :active, null: false
    end.define_model do
      # email is a non-boolean column whose presence CAN be validated in the
      # usual way. We include it in the test model to ensure the detector reports
      # only boolean columns.
      validates :email, :active, presence: true
    end

    assert_problems(<<~OUTPUT)
      replace the `presence` validator on Context::User.active with `inclusion` - `presence` can't be used on booleans
    OUTPUT
  end

  def test_inclusion_is_not_reported
    Context.create_table(:users) do |t|
      t.boolean :active, null: false
    end.define_model do
      validates :active, inclusion: { in: [true, false] }
    end

    refute_problems
  end

  def test_models_with_non_existent_tables_are_skipped
    Context.define_model(:User)

    refute_problems
  end

  def test_config_ignore_models
    Context.create_table(:users) do |t|
      t.boolean :active, null: false
    end.define_model do
      validates :active, presence: true
    end

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :incorrect_boolean_presence_validation,
          ignore_models: ["Context::User"]
      end
    CONFIG

    refute_problems
  end

  def test_config_ignore_models_regexp
    Context.create_table(:users) do |t|
      t.boolean :active, null: false
    end.define_model do
      validates :active, presence: true
    end

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :incorrect_boolean_presence_validation,
          ignore_models: [/User/]
      end
    CONFIG

    refute_problems
  end

  def test_config_ignore_models_class
    Context.create_table(:users) do |t|
      t.boolean :active, null: false
    end.define_model do
      validates :active, presence: true
    end

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :incorrect_boolean_presence_validation,
          ignore_models: [Context::User]
      end
    CONFIG

    refute_problems
  end

  def test_global_ignore_models
    Context.create_table(:users) do |t|
      t.boolean :active, null: false
    end.define_model do
      validates :active, presence: true
    end

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.global :ignore_models, ["Context::User"]
      end
    CONFIG

    refute_problems
  end

  def test_config_ignore_attributes
    Context.create_table(:users) do |t|
      t.boolean :active, null: false
    end.define_model do
      validates :active, presence: true
    end

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :incorrect_boolean_presence_validation,
          ignore_attributes: ["Context::User.active"]
      end
    CONFIG

    refute_problems
  end

  def test_config_ignore_attributes_regexp
    Context.create_table(:users) do |t|
      t.boolean :active_old, null: false
    end.define_model do
      validates :active_old, presence: true
    end

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :incorrect_boolean_presence_validation,
          ignore_attributes: [/_old\\z/]
      end
    CONFIG

    refute_problems
  end
end
