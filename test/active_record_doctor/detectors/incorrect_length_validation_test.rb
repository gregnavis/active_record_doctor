# frozen_string_literal: true

class ActiveRecordDoctor::Detectors::IncorrectLengthValidationTest < Minitest::Test
  def test_validation_and_limit_equal_is_ok
    Context.create_table(:users) do |t|
      t.string :email, limit: 64
      t.string :name, limit: 32
    end.define_model do
      validates :email, length: { maximum: 64 }
      validates :name, length: { maximum: 32 }
    end

    refute_problems
  end

  def test_validation_and_limit_different_is_error
    Context.create_table(:users) do |t|
      t.string :email, limit: 64
    end.define_model do
      validates :email, length: { maximum: 32 }
    end

    assert_problems(<<~OUTPUT)
      the schema limits users.email to 64 characters but the length validator on Context::User.email enforces a maximum of 32 characters - set both limits to the same value or remove both
    OUTPUT
  end

  def test_validation_and_no_limit_is_error
    require_arbitrary_long_text_columns!

    Context.create_table(:users) do |t|
      t.string :email
    end.define_model do
      validates :email, length: { maximum: 32 }
    end

    assert_problems(<<~OUTPUT)
      the length validator on Context::User.email enforces a maximum of 32 characters but there's no schema limit on users.email - remove the validator or the schema length limit
    OUTPUT
  end

  def test_no_validation_and_limit_is_error
    Context.create_table(:users) do |t|
      t.string :email, limit: 64
    end.define_model do
    end

    assert_problems(<<~OUTPUT)
      the schema limits users.email to 64 characters but there's no length validator on Context::User.email - remove the database limit or add the validator
    OUTPUT
  end

  def test_no_validation_and_no_limit_is_ok
    require_arbitrary_long_text_columns!

    Context.create_table(:users) do |t|
      t.string :email
    end.define_model do
    end

    refute_problems
  end

  def test_array_inclusion_validation_with_shorter_values_and_limit_is_ok
    Context.create_table(:users) do |t|
      t.string :status, limit: 64
    end.define_model do
      validates :status, inclusion: { in: ["new", "vip", "a" * 64] }
    end

    refute_problems
  end

  def test_array_inclusion_validation_with_longer_values_and_limit_is_error
    Context.create_table(:users) do |t|
      t.string :status, limit: 64
    end.define_model do
      validates :status, inclusion: { in: ["new", "vip", "a" * 65] }
    end

    assert_problems(<<~OUTPUT)
      the schema limits users.status to 64 characters but there's no length validator on Context::User.status - remove the database limit or add the validator
    OUTPUT
  end

  def test_proc_inclusion_validation_and_limit_is_error
    Context.create_table(:users) do |t|
      t.string :status, limit: 64
    end.define_model do
      validates :status, inclusion: { in: ->(user) {} }
    end

    assert_problems(<<~OUTPUT)
      the schema limits users.status to 64 characters but there's no length validator on Context::User.status - remove the database limit or add the validator
    OUTPUT
  end

  def test_array_inclusion_validation_with_shorter_values_and_if_is_error
    Context.create_table(:users) do |t|
      t.string :status, limit: 64
    end.define_model do
      validates :status, inclusion: { in: ["new", "vip"] }, if: :condition?
    end

    assert_problems(<<~OUTPUT)
      the schema limits users.status to 64 characters but there's no length validator on Context::User.status - remove the database limit or add the validator
    OUTPUT
  end

  def test_array_inclusion_validation_with_shorter_values_and_allow_nil_is_error
    Context.create_table(:users) do |t|
      t.string :status, limit: 64
    end.define_model do
      validates :status, inclusion: { in: ["new", "vip"] }, allow_nil: true
    end

    assert_problems(<<~OUTPUT)
      the schema limits users.status to 64 characters but there's no length validator on Context::User.status - remove the database limit or add the validator
    OUTPUT
  end

  def test_array_inclusion_validation_with_shorter_values_and_disallow_nil_is_ok
    Context.create_table(:users) do |t|
      t.string :status, limit: 64
    end.define_model do
      validates :status, inclusion: { in: ["new", "vip"] }, allow_nil: false
    end

    refute_problems
  end

  def test_config_ignore_models
    Context.create_table(:users) do |t|
      t.string :email, limit: 64
    end.define_model

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :incorrect_length_validation,
          ignore_models: ["Context::User"]
      end
    CONFIG

    refute_problems
  end

  def test_global_ignore_models
    Context.create_table(:users) do |t|
      t.string :email, limit: 64
    end.define_model

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.global :ignore_models, ["Context::User"]
      end
    CONFIG

    refute_problems
  end

  def test_config_ignore_attributes
    Context.create_table(:users) do |t|
      t.string :email, limit: 64
    end.define_model

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :incorrect_length_validation,
          ignore_attributes: ["Context::User.email"]
      end
    CONFIG

    refute_problems
  end
end
