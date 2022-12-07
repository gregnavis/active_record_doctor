# frozen_string_literal: true

class ActiveRecordDoctor::Detectors::MissingNonNullConstraintTest < Minitest::Test
  def test_optional_columns_with_presence_validator_are_disallowed
    create_table(:users) do |t|
      t.string :name, null: true
    end.create_model do
      validates :name, presence: true
    end

    assert_problems(<<~OUTPUT)
      add `NOT NULL` to users.name - models validates its presence but it's not non-NULL in the database
    OUTPUT
  end

  def test_optional_foreign_keys_with_required_association_are_disallowed
    create_table(:companies)
    create_table(:users) do |t|
      t.references :company, null: true
    end.create_model do
      belongs_to :company, required: true
    end

    assert_problems(<<~OUTPUT)
      add `NOT NULL` to users.company_id - models validates its presence but it's not non-NULL in the database
    OUTPUT
  end

  def test_optional_columns_with_required_polymorphic_association_are_disallowed
    create_table(:comments) do |t|
      t.references :commentable, polymorphic: true, null: true
    end.create_model do
      belongs_to :commentable, polymorphic: true, required: true
    end

    assert_problems(<<~OUTPUT)
      add `NOT NULL` to comments.commentable_id - models validates its presence but it's not non-NULL in the database
      add `NOT NULL` to comments.commentable_type - models validates its presence but it's not non-NULL in the database
    OUTPUT
  end

  def test_required_columns_with_required_polymorphic_association_are_allowed
    create_table(:comments) do |t|
      t.references :commentable, polymorphic: true, null: false
    end.create_model do
      belongs_to :commentable, polymorphic: true, required: true
    end

    refute_problems
  end

  def test_required_columns_with_presence_validators_are_allowed
    create_table(:users) do |t|
      t.string :name, null: false
    end.create_model do
      validates :name, presence: true
    end

    refute_problems
  end

  def test_optional_columns_without_presence_validator_are_allowed
    create_table(:users) do |t|
      t.string :name, null: false
    end.create_model do
      validates :name, presence: false
    end

    refute_problems
  end

  def test_validators_matched_to_correct_columns
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

    refute_problems
  end

  def test_validators_with_if_on_optional_columns_are_allowed
    create_table(:users) do |t|
      t.string :name, null: true
    end.create_model do
      validates :name, presence: true, if: -> { false }
    end

    refute_problems
  end

  def test_validators_with_unless_on_optional_columns_are_allowed
    create_table(:users) do |t|
      t.string :name, null: true
    end.create_model do
      validates :name, presence: true, unless: -> { false }
    end

    refute_problems
  end

  def test_validators_allowing_nil_on_optional_columns_are_allowed
    create_table(:users) do |t|
      t.string :name, null: true
    end.create_model do
      validates :name, presence: true, allow_nil: true
    end

    refute_problems
  end

  def test_models_with_non_existent_tables_are_skipped
    create_model(:User)

    refute_problems
  end

  def test_optional_columns_validated_by_all_sti_models_are_disallowed
    create_table(:users) do |t|
      t.string :type, null: false
      t.string :email, null: true
    end.create_model

    create_model(:Client, ModelFactory::Models::User) do
      validates :email, presence: true
    end

    assert_problems(<<~OUTPUT)
      add `NOT NULL` to users.email - models validates its presence but it's not non-NULL in the database
    OUTPUT
  end

  def test_optional_columns_validated_by_some_sti_models_are_allowed
    create_table(:users) do |t|
      t.string :type, null: false
      t.string :email, null: true
    end.create_model

    create_model(:Client, ModelFactory::Models::User) do
      validates :email, presence: true
    end

    create_model(:Admin, ModelFactory::Models::User) do
      validates :email, presence: false
    end

    refute_problems
  end

  def test_optional_columns_validated_by_all_non_sti_models_are_disallowed
    create_table(:users) do |t|
      t.string :email, null: true
    end.create_model do
      validates :email, presence: true
    end

    create_model(:Client) do
      self.table_name = :users

      validates :email, presence: true
    end

    assert_problems(<<~OUTPUT)
      add `NOT NULL` to users.email - models validates its presence but it's not non-NULL in the database
    OUTPUT
  end

  def test_optional_columns_validated_by_some_non_sti_models_are_allowed
    create_table(:users) do |t|
      t.string :email, null: true
    end.create_model do
      validates :email, presence: true
    end

    create_model(:Client) do
      self.table_name = :users

      validates :email, presence: false
    end

    refute_problems
  end

  def test_not_null_check_constraint
    skip unless postgresql?

    create_table(:users) do |t|
      t.string :email
    end.create_model do
      validates :email, presence: true
    end

    ActiveRecord::Base.connection.execute(<<-SQL)
      ALTER TABLE users ADD CONSTRAINT email_not_null CHECK (email IS NOT NULL)
    SQL

    refute_problems
  end

  def test_not_null_check_constraint_not_valid
    skip unless postgresql?

    create_table(:users) do |t|
      t.string :email
    end.create_model do
      validates :email, presence: true
    end

    ActiveRecord::Base.connection.execute(<<-SQL)
      ALTER TABLE users ADD CONSTRAINT email_not_null CHECK (email IS NOT NULL) NOT VALID
    SQL

    assert_problems(<<~OUTPUT)
      add `NOT NULL` to users.email - models validates its presence but it's not non-NULL in the database
    OUTPUT
  end

  def test_config_ignore_tables
    create_table(:users) do |t|
      t.string :name, null: true
    end.create_model do
      validates :name, presence: true
    end

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :missing_non_null_constraint,
          ignore_tables: ["users"]
      end
    CONFIG

    refute_problems
  end

  def test_global_ignore_tables
    create_table(:users) do |t|
      t.string :name, null: true
    end.create_model do
      validates :name, presence: true
    end

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.global :ignore_tables, ["users"]
      end
    CONFIG

    refute_problems
  end

  def test_config_ignore_columns
    create_table(:users) do |t|
      t.string :name, null: true
    end.create_model do
      validates :name, presence: true
    end

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :missing_non_null_constraint,
          ignore_columns: ["users.name"]
      end
    CONFIG

    refute_problems
  end
end
