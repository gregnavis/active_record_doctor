# frozen_string_literal: true

class ActiveRecordDoctor::Detectors::MissingUniqueIndexesTest < Minitest::Test
  def test_missing_unique_index
    Context.create_table(:users) do |t|
      t.string :email
      t.index :email
    end.define_model do
      validates :email, uniqueness: true
    end

    assert_problems(<<~OUTPUT)
      add a unique index on users(email) - validating uniqueness in Context::User without an index can lead to duplicates
    OUTPUT
  end

  def test_missing_unique_index_on_functional_index
    skip if !postgresql?

    Context.create_table(:users) do |t|
      t.string :email
      t.index "lower(email)"
    end.define_model do
      validates :email, uniqueness: true
    end

    # Running the detector should NOT raise an error when a functional index
    # is present. No need to assert anything -- the test is successful if no
    # exception was raised.
    run_detector
  end

  def test_validates_multiple_attributes
    Context.create_table(:users) do |t|
      t.string :email
      t.string :ref_token
    end.define_model do
      validates :email, :ref_token, uniqueness: true
    end

    assert_problems(<<~OUTPUT)
      add a unique index on users(email) - validating uniqueness in Context::User without an index can lead to duplicates
      add a unique index on users(ref_token) - validating uniqueness in Context::User without an index can lead to duplicates
    OUTPUT
  end

  def test_present_unique_index
    Context.create_table(:users) do |t|
      t.string :email
      t.index :email, unique: true
    end.define_model do
      validates :email, uniqueness: true
    end

    refute_problems
  end

  def test_missing_unique_index_reported_only_on_base_class
    Context.create_table(:users) do |t|
      t.string :type
      t.string :email
      t.string :name
    end.define_model do
      validates :email, uniqueness: true
    end

    Context.define_model(:Client, Context::User) do
      validates :name, uniqueness: true
    end

    assert_problems(<<~OUTPUT)
      add a unique index on users(email) - validating uniqueness in Context::User without an index can lead to duplicates
      add a unique index on users(name) - validating uniqueness in Context::Client without an index can lead to duplicates
    OUTPUT
  end

  def test_present_partial_unique_index
    require_partial_indexes!

    Context.create_table(:users) do |t|
      t.string :email
      t.boolean :active
      t.index :email, unique: true, where: "active"
    end.define_model do
      validates :email, uniqueness: true
    end

    assert_problems(<<~OUTPUT)
      add a unique index on users(email) - validating uniqueness in Context::User without an index can lead to duplicates
    OUTPUT
  end

  def test_unique_index_with_extra_columns_with_scope
    Context.create_table(:users) do |t|
      t.string :email
      t.integer :company_id
      t.integer :department_id
      t.index [:company_id, :department_id, :email]
    end.define_model do
      validates :email, uniqueness: { scope: [:company_id, :department_id] }
    end

    assert_problems(<<~OUTPUT)
      add a unique index on users(company_id, department_id, email) - validating uniqueness in Context::User without an index can lead to duplicates
    OUTPUT
  end

  def test_unique_index_with_exact_columns_with_scope
    Context.create_table(:users) do |t|
      t.string :email
      t.integer :company_id
      t.integer :department_id
      t.index [:company_id, :department_id, :email], unique: true
    end.define_model do
      validates :email, uniqueness: { scope: [:company_id, :department_id] }
    end

    refute_problems
  end

  def test_unique_index_with_fewer_columns_with_scope
    Context.create_table(:users) do |t|
      t.string :email
      t.integer :company_id
      t.integer :department_id
      t.index [:company_id, :department_id], unique: true
    end.define_model do
      validates :email, uniqueness: { scope: [:company_id, :department_id] }
    end

    refute_problems
  end

  def test_missing_unique_index_with_association_attribute
    Context.create_table(:users) do |t|
      t.integer :account_id
    end.define_model do
      belongs_to :account
      validates :account, uniqueness: true
    end

    assert_problems(<<~OUTPUT)
      add a unique index on users(account_id) - validating uniqueness in Context::User without an index can lead to duplicates
    OUTPUT
  end

  def test_present_unique_index_with_association_attribute
    Context.create_table(:users) do |t|
      t.integer :account_id
      t.index :account_id, unique: true
    end.define_model do
      belongs_to :account
      validates :account, uniqueness: true
    end

    refute_problems
  end

  def test_missing_unique_index_with_association_scope
    Context.create_table(:comments) do |t|
      t.string :title
      t.integer :commentable_id
      t.string :commentable_type
    end.define_model do
      belongs_to :commentable, polymorphic: true
      validates :title, uniqueness: { scope: :commentable }
    end

    assert_problems(<<~OUTPUT)
      add a unique index on comments(commentable_type, commentable_id, title) - validating uniqueness in Context::Comment without an index can lead to duplicates
    OUTPUT
  end

  def test_present_unique_index_with_association_scope
    Context.create_table(:comments) do |t|
      t.string :title
      t.integer :commentable_id
      t.string :commentable_type
      t.index [:commentable_id, :commentable_type, :title], unique: true
    end.define_model do
      belongs_to :commentable, polymorphic: true
      validates :title, uniqueness: { scope: :commentable }
    end

    refute_problems
  end

  def test_column_order_is_ignored
    Context.create_table(:users) do |t|
      t.string :email
      t.integer :organization_id

      t.index [:email, :organization_id], unique: true
    end.define_model do
      validates :email, uniqueness: { scope: :organization_id }
    end

    refute_problems
  end

  def test_case_insensitive_unique_index_exists
    require_expression_indexes!

    Context.create_table(:users) do |t|
      t.string :email

      t.index :email, unique: true
    end.define_model do
      validates :email, uniqueness: { case_sensitive: false }
    end

    assert_problems(<<~OUTPUT)
      add a unique expression index on users(lower(email)) - validating case-insensitive uniqueness in Context::User without an expression index can lead to duplicates (a regular unique index is not enough)
    OUTPUT
  end

  def test_case_insensitive_non_unique_lower_index_exists
    require_expression_indexes!

    Context.create_table(:users) do |t|
      t.string :email
    end.define_model do
      validates :email, uniqueness: { case_sensitive: false }
    end

    # ActiveRecord < 5 does not support expression indexes.
    ActiveRecord::Base.connection.execute(<<-SQL)
      CREATE INDEX index_users_on_lower_email ON users ((lower(email)))
    SQL

    assert_problems(<<~OUTPUT)
      add a unique expression index on users(lower(email)) - validating case-insensitive uniqueness in Context::User without an expression index can lead to duplicates (a regular unique index is not enough)
    OUTPUT
  end

  def test_case_insensitive_unique_lower_index_exists
    require_expression_indexes!

    Context.create_table(:users) do |t|
      t.string :email
    end.define_model do
      validates :email, uniqueness: { case_sensitive: false }
    end

    # ActiveRecord < 5 does not support expression indexes.
    ActiveRecord::Base.connection.execute(<<-SQL)
      CREATE UNIQUE INDEX index_users_on_lower_email ON users ((lower(email)))
    SQL

    refute_problems
  end

  def test_case_insensitive_compound_unique_index_exists
    require_expression_indexes!

    Context.create_table(:users) do |t|
      t.string :email
      t.integer :organization_id
      t.index [:email, :organization_id], unique: true
    end.define_model do
      validates :email, uniqueness: { scope: :organization_id, case_sensitive: false }
    end

    assert_problems(<<~OUTPUT)
      add a unique expression index on users(organization_id, lower(email)) - validating case-insensitive uniqueness in Context::User without an expression index can lead to duplicates (a regular unique index is not enough)
    OUTPUT
  end

  def test_case_insensitive_compound_non_unique_lower_index_exists
    require_expression_indexes!

    Context.create_table(:users) do |t|
      t.string :email
      t.integer :organization_id
    end.define_model do
      validates :email, uniqueness: { scope: :organization_id, case_sensitive: false }
    end

    ActiveRecord::Base.connection.execute(<<-SQL)
      CREATE INDEX index_users_on_lower_email_and_organization_id ON users ((lower(email)), organization_id)
    SQL

    assert_problems(<<~OUTPUT)
      add a unique expression index on users(organization_id, lower(email)) - validating case-insensitive uniqueness in Context::User without an expression index can lead to duplicates (a regular unique index is not enough)
    OUTPUT
  end

  def test_case_insensitive_compound_unique_lower_index_exists
    require_expression_indexes!

    Context.create_table(:users) do |t|
      t.string :email
      t.integer :organization_id
    end.define_model do
      validates :email, uniqueness: { scope: :organization_id, case_sensitive: false }
    end

    ActiveRecord::Base.connection.execute(<<-SQL)
      CREATE UNIQUE INDEX index_users_on_lower_email_and_organization_id ON users ((lower(email)), organization_id)
    SQL

    refute_problems
  end

  def test_case_insensitive_unique_index_with_citext
    require_citext!

    ActiveRecord::Base.connection.enable_extension(:citext)

    Context.create_table(:users) do |t|
      t.citext :email
      t.index :email, unique: true
    end.define_model do
      validates :email, uniqueness: { case_sensitive: false }
    end

    # CITEXT is case-insensitive, so a unique index on it is enough to
    # guarantee case-insensitive uniqueness.
    refute_problems
  end

  def test_case_insensitive_compound_unique_index_with_citext
    require_expression_indexes!
    require_citext!

    ActiveRecord::Base.connection.enable_extension(:citext)

    Context.create_table(:users) do |t|
      t.citext :email
      t.integer :organization_id

      t.index [:email, :organization_id], unique: true
    end.define_model do
      validates :email, uniqueness: { scope: :organization_id, case_sensitive: false }
    end

    refute_problems
  end

  def test_conditions_is_skipped
    assert_skipped(conditions: -> { where.not(email: nil) })
  end

  def test_if_is_skipped
    assert_skipped(if: ->(_model) { true })
  end

  def test_unless_is_skipped
    assert_skipped(unless: ->(_model) { true })
  end

  def test_skips_validator_without_attributes
    Context.create_table(:users) do |t|
      t.string :email
      t.index :email
    end.define_model do
      validates_with DummyValidator
    end

    refute_problems
  end

  def test_has_one_without_index
    Context.create_table(:users)
           .define_model do
      has_one :account, class_name: "Context::Account"
      has_one :account_history, through: :account, class_name: "Context::Account"
    end

    Context.create_table(:accounts) do |t|
      t.integer :user_id
    end.define_model do
      has_one :account_history, class_name: "Context::AccountHistory"
    end

    Context.create_table(:account_histories) do |t|
      t.integer :account_id
    end.define_model do
      belongs_to :account,  class_name: "Context::Account"
    end

    assert_problems(<<~OUTPUT)
      add a unique index on accounts(user_id) - using `has_one` in Context::User without an index can lead to duplicates
      add a unique index on account_histories(account_id) - using `has_one` in Context::Account without an index can lead to duplicates
    OUTPUT
  end

  def test_has_one_with_scope_and_without_index
    Context.create_table(:users)
           .define_model do
      has_one :last_comment, -> { order(created_at: :desc) }, class_name: "Context::Comment"
    end

    Context.create_table(:comments) do |t|
      t.integer :user_id
    end.define_model

    refute_problems
  end

  def test_missing_has_one_unique_index_reported_only_on_base_class
    Context.create_table(:users) do |t|
      t.string :type
    end.define_model do
      has_one :account, class_name: "Context::Account"
    end

    Context.define_model(:Client, Context::User)

    Context.create_table(:accounts) do |t|
      t.integer :user_id
    end.define_model

    assert_problems(<<~OUTPUT)
      add a unique index on accounts(user_id) - using `has_one` in Context::User without an index can lead to duplicates
    OUTPUT
  end

  def test_has_one_with_index
    Context.create_table(:users)
           .define_model do
      has_one :account, class_name: "Context::Account"
    end

    Context.create_table(:accounts) do |t|
      t.integer :user_id, index: { unique: true }
    end.define_model

    refute_problems
  end

  def test_polymorphic_has_one_without_index
    Context.create_table(:users)
           .define_model do
      has_one :account, as: :accountable
    end

    Context.create_table(:accounts) do |t|
      t.belongs_to :accountable, polymorphic: true, index: false
    end.define_model do
      belongs_to :accountable, polymorphic: true
    end

    assert_problems(<<~OUTPUT)
      add a unique index on accounts(accountable_type, accountable_id) - using `has_one` in Context::User without an index can lead to duplicates
    OUTPUT
  end

  def test_polymorphic_has_one_with_index
    Context.create_table(:users)
           .define_model do
      has_one :account, as: :accountable
    end

    Context.create_table(:accounts) do |t|
      t.belongs_to :accountable, polymorphic: true, index: { unique: true }
    end.define_model do
      belongs_to :accountable, polymorphic: true
    end

    refute_problems
  end

  def test_has_one_on_primary_key_column
    Context
      .create_table(:parents)
      .define_model do
        has_one :child
      end

    Context
      .create_table(:children, primary_key: :parent_id)
      .define_model do
        belongs_to :parent
      end

    refute_problems
  end

  def test_has_and_belongs_to_many_without_index
    Context
      .create_table(:users)
      .define_model do
        has_and_belongs_to_many :roles
      end

    Context.create_table(:roles_users) do |t|
      t.integer :user_id
      t.integer :role_id
    end

    Context
      .create_table(:roles)
      .define_model do
        has_and_belongs_to_many :users
      end

    assert_problems(<<~OUTPUT)
      add a unique index on roles_users(role_id, user_id) - using `has_and_belongs_to_many` in Context::Role without an index can lead to duplicates
    OUTPUT
  end

  def test_has_and_belongs_to_many_with_scope_and_without_index
    Context
      .create_table(:users)
      .define_model do
        has_and_belongs_to_many :roles, -> { unique }
      end

    Context
      .create_table(:roles)
      .define_model do
        has_and_belongs_to_many :users, -> { unique }
      end

    refute_problems
  end

  def test_has_and_belongs_to_many_with_index
    Context
      .create_table(:users)
      .define_model do
        has_and_belongs_to_many :roles
      end

    Context.create_table(:roles_users) do |t|
      t.integer :user_id
      t.integer :role_id
      t.index [:user_id, :role_id], unique: true
    end

    Context
      .create_table(:roles)
      .define_model do
        has_and_belongs_to_many :users
      end

    refute_problems
  end

  def test_config_ignore_models
    Context.create_table(:users) do |t|
      t.string :email
    end.define_model do
      validates :email, uniqueness: true
    end

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :missing_unique_indexes,
          ignore_models: ["Context::User"]
      end
    CONFIG

    refute_problems
  end

  def test_global_ignore_models
    Context.create_table(:users) do |t|
      t.string :email
    end.define_model do
      validates :email, uniqueness: true
    end

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.global :ignore_models, ["Context::User"]
      end
    CONFIG

    refute_problems
  end

  def test_config_ignore_columns
    Context.create_table(:users) do |t|
      t.string :email
      t.integer :role
    end.define_model do
      validates :email, :role, uniqueness: { scope: :organization_id }
    end

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :missing_unique_indexes,
          ignore_columns: ["Context::User(organization_id, email)", "Context::User(organization_id, role)"]
      end
    CONFIG

    refute_problems
  end

  def test_config_ignore_case_insensitive_columns
    Context.create_table(:users) do |t|
      t.string :email
    end.define_model do
      validates :email, uniqueness: { case_sensitive: false }
    end

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :missing_unique_indexes,
          ignore_columns: ["Context::User(lower(email))"]
      end
    CONFIG

    refute_problems
  end

  def test_config_ignore_columns_for_has_one
    Context.create_table(:users).define_model do
      has_one :account, class_name: "Context::Account"
    end

    Context.create_table(:accounts) do |t|
      t.integer :user_id
    end.define_model

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :missing_unique_indexes,
          ignore_columns: ["Context::Account(user_id)"]
      end
    CONFIG

    refute_problems
  end

  def test_config_ignore_join_tables
    Context
      .create_table(:users)
      .define_model do
        has_and_belongs_to_many :roles
      end

    Context.create_table(:roles_users) do |t|
      t.integer :user_id
      t.integer :role_id
    end

    Context
      .create_table(:roles)
      .define_model do
        has_and_belongs_to_many :users
      end

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :missing_unique_indexes,
          ignore_join_tables: ["roles_users"]
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
    Context.create_table(:users) do |t|
      t.string :email
    end.define_model do
      validates :email, uniqueness: options
    end

    refute_problems
  end
end
