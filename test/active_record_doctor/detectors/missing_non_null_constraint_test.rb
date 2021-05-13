# frozen_string_literal: true

class ActiveRecordDoctor::Detectors::MissingNonNullConstraintTest < Minitest::Test
  def test_presence_true_and_null_true
    create_table(:users) do |t|
      t.string :name, null: true
    end.create_model do
      validates :name, presence: true
    end

    assert_success(<<OUTPUT)
The following columns should be marked as `null: false`:
  users: name
OUTPUT
  end

  def test_association_presence_true_and_null_true
    create_table(:companies)
    create_table(:users) do |t|
      t.references :company
    end.create_model do
      belongs_to :company, required: true
    end

    assert_success(<<OUTPUT)
The following columns should be marked as `null: false`:
  users: company_id
OUTPUT
  end

  def test_presence_true_and_null_false
    create_table(:users) do |t|
      t.string :name, null: false
    end.create_model do
      validates :name, presence: true
    end

    assert_success("")
  end

  def test_presence_false_and_null_true
    create_table(:users) do |t|
      t.string :name, null: true
    end.create_model do
      # The age validator is a form of regression test against a bug that
      # caused false positives. In this test case, name is NOT validated
      # for presence so it does NOT need be marked non-NULL. However, the
      # bug would match the age presence validator with the NULL-able name
      # column which would result in a false positive error report.
      validates :age, presence: true
      validates :name, presence: false
    end

    assert_success("")
  end

  def test_presence_false_and_null_false
    create_table(:users) do |t|
      t.string :name, null: false
    end.create_model do
      validates :name, presence: false
    end

    assert_success("")
  end

  def test_presence_true_with_if
    create_table(:users) do |t|
      t.string :name, null: true
    end.create_model do
      validates :name, presence: true, if: -> { false }
    end

    assert_success("")
  end

  def test_presence_true_with_unless
    create_table(:users) do |t|
      t.string :name, null: true
    end.create_model do
      validates :name, presence: true, unless: -> { false }
    end

    assert_success("")
  end

  def test_presence_true_with_allow_nil
    create_table(:users) do |t|
      t.string :name, null: true
    end.create_model do
      validates :name, presence: true, allow_nil: true
    end

    assert_success("")
  end

  def test_models_with_non_existent_tables_are_skipped
    create_model(:users)

    assert_success("")
  end
end
