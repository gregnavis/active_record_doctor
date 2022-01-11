# frozen_string_literal: true

class ActiveRecordDoctor::Detectors::MissingUniqueIndexesTest < Minitest::Test
  def test_missing_unique_index
    create_table(:users) do |t|
      t.string :email
      t.index :email
    end.create_model do
      validates :email, uniqueness: true
    end

    assert_problems(<<~OUTPUT)
      add a unique index on users(email) - validating uniqueness in the model without an index can lead to duplicates
    OUTPUT
  end

  def test_missing_unique_index_on_functional_index
    skip if !(ActiveRecord::VERSION::STRING >= "5.0" && postgresql?)

    create_table(:users) do |t|
      t.string :email
      t.index "lower(email)"
    end.create_model do
      validates :email, uniqueness: true
    end

    # Running the detector should NOT raise an error when a functional index
    # is present. No need to assert anything -- the test is successful if no
    # exception was raised.
    run_detector
  end

  def test_validates_multiple_attributes
    create_table(:users) do |t|
      t.string :email
      t.string :ref_token
    end.create_model do
      validates :email, :ref_token, uniqueness: true
    end

    assert_problems(<<~OUTPUT)
      add a unique index on users(email) - validating uniqueness in the model without an index can lead to duplicates
      add a unique index on users(ref_token) - validating uniqueness in the model without an index can lead to duplicates
    OUTPUT
  end

  def test_present_unique_index
    create_table(:users) do |t|
      t.string :email
      t.index :email, unique: true
    end.create_model do
      validates :email, uniqueness: true
    end

    refute_problems
  end

  def test_present_partial_unique_index
    skip("MySQL doesn't support partial indexes") if mysql?

    create_table(:users) do |t|
      t.string :email
      t.boolean :active
      t.index :email, unique: true, where: "active"
    end.create_model do
      validates :email, uniqueness: true
    end

    assert_problems(<<~OUTPUT)
      add a unique index on users(email) - validating uniqueness in the model without an index can lead to duplicates
    OUTPUT
  end

  def test_unique_index_with_extra_columns_with_scope
    create_table(:users) do |t|
      t.string :email
      t.integer :company_id
      t.integer :department_id
      t.index [:company_id, :department_id, :email]
    end.create_model do
      validates :email, uniqueness: { scope: [:company_id, :department_id] }
    end

    assert_problems(<<~OUTPUT)
      add a unique index on users(company_id, department_id, email) - validating uniqueness in the model without an index can lead to duplicates
    OUTPUT
  end

  def test_unique_index_with_exact_columns_with_scope
    create_table(:users) do |t|
      t.string :email
      t.integer :company_id
      t.integer :department_id
      t.index [:company_id, :department_id, :email], unique: true
    end.create_model do
      validates :email, uniqueness: { scope: [:company_id, :department_id] }
    end

    refute_problems
  end

  def test_unique_index_with_fewer_columns_with_scope
    create_table(:users) do |t|
      t.string :email
      t.integer :company_id
      t.integer :department_id
      t.index [:company_id, :department_id], unique: true
    end.create_model do
      validates :email, uniqueness: { scope: [:company_id, :department_id] }
    end

    refute_problems
  end

  def test_missing_unique_index_with_association_attribute
    create_table(:users) do |t|
      t.integer :account_id
    end.create_model do
      belongs_to :account
      validates :account, uniqueness: true
    end

    assert_problems(<<~OUTPUT)
      add a unique index on users(account_id) - validating uniqueness in the model without an index can lead to duplicates
    OUTPUT
  end

  def test_present_unique_index_with_association_attribute
    create_table(:users) do |t|
      t.integer :account_id
      t.index :account_id, unique: true
    end.create_model do
      belongs_to :account
      validates :account, uniqueness: true
    end

    refute_problems
  end

  def test_missing_unique_index_with_association_scope
    create_table(:comments) do |t|
      t.string :title
      t.integer :commentable_id
      t.string :commentable_type
    end.create_model do
      belongs_to :commentable, polymorphic: true
      validates :title, uniqueness: { scope: :commentable }
    end

    assert_problems(<<~OUTPUT)
      add a unique index on comments(commentable_type, commentable_id, title) - validating uniqueness in the model without an index can lead to duplicates
    OUTPUT
  end

  def test_present_unique_index_with_association_scope
    create_table(:comments) do |t|
      t.string :title
      t.integer :commentable_id
      t.string :commentable_type
      t.index [:commentable_id, :commentable_type, :title], unique: true
    end.create_model do
      belongs_to :commentable, polymorphic: true
      validates :title, uniqueness: { scope: :commentable }
    end

    refute_problems
  end

  def test_column_order_is_ignored
    create_table(:users) do |t|
      t.string :email
      t.integer :organization_id

      t.index [:email, :organization_id], unique: true
    end.create_model do
      validates :email, uniqueness: { scope: :organization_id }
    end

    refute_problems
  end

  def test_conditions_is_skipped
    assert_skipped(conditions: -> { where.not(email: nil) })
  end

  def test_case_insensitive_is_skipped
    assert_skipped(case_sensitive: false)
  end

  def test_if_is_skipped
    assert_skipped(if: ->(_model) { true })
  end

  def test_unless_is_skipped
    assert_skipped(unless: ->(_model) { true })
  end

  def test_skips_validator_without_attributes
    create_table(:users) do |t|
      t.string :email
      t.index :email
    end.create_model do
      validates_with DummyValidator
    end

    refute_problems
  end

  def test_has_one_without_index
    create_table(:users)
      .create_model do
        has_one :account, class_name: "ModelFactory::Models::Account"
        has_one :account_history, through: :account, class_name: "ModelFactory::Models::Account"
      end

    create_table(:accounts) do |t|
      t.integer :user_id
    end.create_model do
      has_one :account_history, class_name: "ModelFactory::Models::AccountHistory"
    end

    create_table(:account_histories) do |t|
      t.integer :account_id
    end.create_model do
      belongs_to :account,  class_name: "ModelFactory::Models::Account"
    end

    assert_problems(<<~OUTPUT)
      add a unique index on accounts(user_id) - using `has_one` in the ModelFactory::Models::User model without an index can lead to duplicates
      add a unique index on account_histories(account_id) - using `has_one` in the ModelFactory::Models::Account model without an index can lead to duplicates
    OUTPUT
  end

  def test_has_one_with_scope_and_without_index
    create_table(:users)
      .create_model do
        has_one :last_comment, -> { order(created_at: :desc) }, class_name: "ModelFactory::Models::Comment"
      end

    create_table(:comments) do |t|
      t.integer :user_id
    end.create_model

    refute_problems
  end

  def test_has_one_with_index
    create_table(:users)
      .create_model do
        has_one :account, class_name: "ModelFactory::Models::Account"
      end

    create_table(:accounts) do |t|
      t.integer :user_id, index: { unique: true }
    end.create_model

    refute_problems
  end

  def test_config_ignore_models
    create_table(:users) do |t|
      t.string :email
    end.create_model do
      validates :email, uniqueness: true
    end

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :missing_unique_indexes,
          ignore_models: ["ModelFactory::Models::User"]
      end
    CONFIG

    refute_problems
  end

  def test_global_ignore_models
    create_table(:users) do |t|
      t.string :email
    end.create_model do
      validates :email, uniqueness: true
    end

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.global :ignore_models, ["ModelFactory::Models::User"]
      end
    CONFIG

    refute_problems
  end

  def test_config_ignore_columns
    create_table(:users) do |t|
      t.string :email
      t.integer :role
    end.create_model do
      validates :email, :role, uniqueness: { scope: :organization_id }
    end

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :missing_unique_indexes,
          ignore_columns: ["ModelFactory::Models::User(organization_id, email)", "ModelFactory::Models::User(organization_id, role)"]
      end
    CONFIG

    refute_problems
  end

  class DummyValidator < ActiveModel::Validator
    def validate(record)
    end
  end

  private

  def assert_skipped(options)
    create_table(:users) do |t|
      t.string :email
    end.create_model do
      validates :email, uniqueness: options
    end

    refute_problems
  end
end
