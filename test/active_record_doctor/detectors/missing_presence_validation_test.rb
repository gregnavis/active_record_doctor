# frozen_string_literal: true

class ActiveRecordDoctor::Detectors::MissingPresenceValidationTest < Minitest::Test
  def test_null_column_is_not_reported_if_validation_absent
    create_table(:users) do |t|
      t.string :name
    end.create_model do
    end

    refute_problems
  end

  def test_non_null_column_is_reported_if_validation_absent
    create_table(:users) do |t|
      t.string :name, null: false
    end.create_model do
    end

    assert_problems(<<OUTPUT)
The following models and columns should have presence validations:
  ModelFactory::Models::User: name
OUTPUT
  end

  def test_non_null_column_is_not_reported_if_validation_present
    create_table(:users) do |t|
      t.string :name, null: false
    end.create_model do
      validates :name, presence: true
    end

    refute_problems
  end

  def test_non_null_column_is_not_reported_if_association_validation_present
    create_table(:companies).create_model
    create_table(:users) do |t|
      t.references :company, null: false
    end.create_model do
      belongs_to :company, required: true
    end

    refute_problems
  end

  def test_non_null_boolean_is_reported_if_nil_included
    create_table(:users) do |t|
      t.boolean :active, null: false
    end.create_model do
      validates :active, inclusion: { in: [nil, true, false] }
    end

    assert_problems(<<OUTPUT)
The following models and columns should have presence validations:
  ModelFactory::Models::User: active
OUTPUT
  end

  def test_non_null_boolean_is_not_reported_if_nil_not_included
    create_table(:users) do |t|
      t.boolean :active, null: false
    end.create_model do
      validates :active, inclusion: { in: [true, false] }
    end

    refute_problems
  end

  def test_non_null_boolean_is_not_reported_if_nil_excluded
    create_table(:users) do |t|
      t.boolean :active, null: false
    end.create_model do
      validates :active, exclusion: { in: [nil] }
    end

    refute_problems
  end

  def test_non_null_boolean_is_reported_if_nil_not_excluded
    create_table(:users) do |t|
      t.boolean :active, null: false
    end.create_model do
      validates :active, exclusion: { in: [false] }
    end

    assert_problems(<<OUTPUT)
The following models and columns should have presence validations:
  ModelFactory::Models::User: active
OUTPUT
  end

  def test_timestamps_are_not_reported
    create_table(:users) do |t|
      t.timestamps null: false
    end.create_model do
      validates :name, presence: true
    end

    refute_problems
  end

  def test_models_with_non_existent_tables_are_skipped
    create_model(:users)

    refute_problems
  end
end
