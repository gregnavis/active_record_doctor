# frozen_string_literal: true

class ActiveRecordDoctor::Detectors::IncorrectLengthValidationTest < Minitest::Test
  def test_validation_and_limit_equal_is_ok
    create_table(:users) do |t|
      t.string :email, limit: 64
    end.create_model do
      validates :email, length: { maximum: 64 }
    end

    refute_problems
  end

  def test_validation_and_limit_different_is_error
    create_table(:users) do |t|
      t.string :email, limit: 64
    end.create_model do
      validates :email, length: { maximum: 32 }
    end

    assert_problems(<<~OUTPUT)
      the schema limits users.email to 64 characters but the length validator on ModelFactory::Models::User.email enforces a maximum of 32 characters - set both limits to the same value or remove both
    OUTPUT
  end

  def test_validation_and_no_limit_is_error
    skip("MySQL always sets a limit on text columns") if mysql?

    create_table(:users) do |t|
      t.string :email
    end.create_model do
      validates :email, length: { maximum: 32 }
    end

    assert_problems(<<~OUTPUT)
      the length validator on ModelFactory::Models::User.email enforces a maximum of 32 characters but there's no schema limit on users.email - remove the validator or the schema length limit
    OUTPUT
  end

  def test_no_validation_and_limit_is_error
    create_table(:users) do |t|
      t.string :email, limit: 64
    end.create_model do
    end

    assert_problems(<<~OUTPUT)
      the schema limits users.email to 64 characters but there's no length validator on ModelFactory::Models::User.email - remove the database limit or add the validator
    OUTPUT
  end

  def test_no_validation_and_no_limit_is_ok
    skip("MySQL always sets a limit on text columns") if mysql?

    create_table(:users) do |t|
      t.string :email
    end.create_model do
    end

    refute_problems
  end

  def test_config_ignore_models
    create_table(:users) do |t|
      t.string :email, limit: 64
    end.create_model

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :incorrect_length_validation,
          ignore_models: ["ModelFactory::Models::User"]
      end
    CONFIG

    refute_problems
  end

  def test_global_ignore_models
    create_table(:users) do |t|
      t.string :email, limit: 64
    end.create_model

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.global :ignore_models, ["ModelFactory::Models::User"]
      end
    CONFIG

    refute_problems
  end

  def test_config_ignore_attributes
    create_table(:users) do |t|
      t.string :email, limit: 64
    end.create_model

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :incorrect_length_validation,
          ignore_attributes: ["ModelFactory::Models::User.email"]
      end
    CONFIG

    refute_problems
  end
end
