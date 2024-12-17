# frozen_string_literal: true

class ActiveRecordDoctor::Detectors::MissingNonNullConstraintTest < Minitest::Test
  def test_optional_columns_with_presence_validator_are_disallowed
    Context.create_table(:users) do |t|
      t.string :name, null: true
    end.define_model do
      validates :name, presence: true
    end

    assert_problems(<<~OUTPUT)
      add `NOT NULL` to users.name - models validates its presence but it's not non-NULL in the database
    OUTPUT
  end

  def test_optional_foreign_keys_with_required_association_are_disallowed
    Context.create_table(:companies)
    Context.create_table(:users) do |t|
      t.references :company, null: true
    end.define_model do
      belongs_to :company, required: true
    end

    assert_problems(<<~OUTPUT)
      add `NOT NULL` to users.company_id - models validates its presence but it's not non-NULL in the database
    OUTPUT
  end

  def test_optional_columns_with_required_polymorphic_association_are_disallowed
    Context.create_table(:comments) do |t|
      t.references :commentable, polymorphic: true, null: true
    end.define_model do
      belongs_to :commentable, polymorphic: true, required: true
    end

    assert_problems(<<~OUTPUT)
      add `NOT NULL` to comments.commentable_id - models validates its presence but it's not non-NULL in the database
      add `NOT NULL` to comments.commentable_type - models validates its presence but it's not non-NULL in the database
    OUTPUT
  end

  def test_optional_foreign_keys_with_required_with_if_association_are_disallowed
    require_optimized_association_presence_validations!

    begin
      previous = ActiveRecord.belongs_to_required_validates_foreign_key
      ActiveRecord.belongs_to_required_validates_foreign_key = false

      Context.create_table(:companies)
      Context.create_table(:users) do |t|
        t.references :company, null: true
      end.define_model do
        belongs_to :company, required: true
      end

      assert_problems(<<~OUTPUT)
        add `NOT NULL` to users.company_id - models validates its presence but it's not non-NULL in the database
      OUTPUT
    ensure
      ActiveRecord.belongs_to_required_validates_foreign_key = previous
    end
  end

  def test_required_columns_with_required_polymorphic_association_are_allowed
    Context.create_table(:comments) do |t|
      t.references :commentable, polymorphic: true, null: false
    end.define_model do
      belongs_to :commentable, polymorphic: true, required: true
    end

    refute_problems
  end

  def test_required_columns_with_presence_validators_are_allowed
    Context.create_table(:users) do |t|
      t.string :name, null: false
    end.define_model do
      validates :name, presence: true
    end

    refute_problems
  end

  def test_optional_columns_without_presence_validator_are_allowed
    Context.create_table(:users) do |t|
      t.string :name, null: false
    end.define_model do
      validates :name, presence: false
    end

    refute_problems
  end

  def test_validators_matched_to_correct_columns
    Context.create_table(:users) do |t|
      t.string :name, null: true
    end.define_model do
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
    Context.create_table(:users) do |t|
      t.string :name, null: true
    end.define_model do
      validates :name, presence: true, if: -> { false }
    end

    refute_problems
  end

  def test_validators_with_unless_on_optional_columns_are_allowed
    Context.create_table(:users) do |t|
      t.string :name, null: true
    end.define_model do
      validates :name, presence: true, unless: -> { false }
    end

    refute_problems
  end

  def test_validators_allowing_nil_on_optional_columns_are_allowed
    Context.create_table(:users) do |t|
      t.string :name, null: true
    end.define_model do
      validates :name, presence: true, allow_nil: true
    end

    refute_problems
  end

  def test_validators_with_specific_context_on_optional_columns_are_allowed
    Context.create_table(:users) do |t|
      t.string :name, null: true
    end.define_model do
      validates :name, presence: true, on: :create
    end

    refute_problems
  end

  def test_models_with_non_existent_tables_are_skipped
    Context.define_model(:User)

    refute_problems
  end

  def test_optional_columns_validated_by_all_sti_models_are_disallowed
    Context.create_table(:users) do |t|
      t.string :type, null: false
      t.string :email, null: true
    end.define_model

    Context.define_model(:Client, Context::User) do
      validates :email, presence: true
    end

    assert_problems(<<~OUTPUT)
      add `NOT NULL` to users.email - models validates its presence but it's not non-NULL in the database
    OUTPUT
  end

  def test_optional_columns_validated_by_some_sti_models_are_allowed
    Context.create_table(:users) do |t|
      t.string :type, null: false
      t.string :email, null: true
    end.define_model

    Context.define_model(:Client, Context::User) do
      validates :email, presence: true
    end

    Context.define_model(:Admin, Context::User) do
      validates :email, presence: false
    end

    refute_problems
  end

  def test_optional_columns_validated_by_all_non_sti_models_are_disallowed
    Context.create_table(:users) do |t|
      t.string :email, null: true
    end.define_model do
      validates :email, presence: true
    end

    Context.define_model(:Client) do
      self.table_name = :users

      validates :email, presence: true
    end

    assert_problems(<<~OUTPUT)
      add `NOT NULL` to users.email - models validates its presence but it's not non-NULL in the database
    OUTPUT
  end

  def test_optional_columns_validated_by_some_non_sti_models_are_allowed
    Context.create_table(:users) do |t|
      t.string :email, null: true
    end.define_model do
      validates :email, presence: true
    end

    Context.define_model(:Client) do
      self.table_name = :users

      validates :email, presence: false
    end

    refute_problems
  end

  def test_sti_column_is_ignored
    Context.create_table(:users) do |t|
      t.string :type
    end.define_model

    refute_problems
  end

  def test_custom_sti_column_is_ignored
    Context.create_table(:users) do |t|
      t.string :custom_type
    end.define_model do
      self.inheritance_column = :custom_type
    end

    refute_problems
  end

  def test_not_null_check_constraint
    Context.create_table(:users) do |t|
      if !sqlite?
        t.string :email
      end
    end.define_model do
      validates :email, presence: true
    end

    if sqlite?
      ActiveRecord::Base.connection.execute(<<-SQL)
        ALTER TABLE users ADD COLUMN email VARCHAR CONSTRAINT email_not_null CHECK (email IS NOT NULL)
      SQL
    else
      ActiveRecord::Base.connection.execute(<<-SQL)
        ALTER TABLE users ADD CONSTRAINT email_not_null CHECK (email IS NOT NULL)
      SQL
    end

    refute_problems
  end

  def test_views_are_ignored
    Context.create_table(:old_comments, force: true) do |t|
      t.integer :user_id
    end

    Context.execute(<<-SQL)
      CREATE VIEW comments AS SELECT * FROM old_comments
    SQL

    Context.define_model(:Comment) do
      belongs_to :user, required: true
    end

    refute_problems
  ensure
    Context.execute("DROP VIEW comments")
  end

  def test_config_ignore_tables
    Context.create_table(:users) do |t|
      t.string :name, null: true
    end.define_model do
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
    Context.create_table(:users) do |t|
      t.string :name, null: true
    end.define_model do
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
    Context.create_table(:users) do |t|
      t.string :name, null: true
    end.define_model do
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

  def test_timestamps_with_null_are_disallowed
    Context.create_table(:users) do |t|
      t.timestamps null: true
    end.define_model

    assert_problems(<<~OUTPUT)
      add `NOT NULL` to users.created_at - timestamp columns are set automatically by Active Record and allowing NULL may lead to inconsistencies introduced by bulk operations
      add `NOT NULL` to users.updated_at - timestamp columns are set automatically by Active Record and allowing NULL may lead to inconsistencies introduced by bulk operations
    OUTPUT
  end

  def test_created_on_updated_on_with_null_are_disallowed
    Context.create_table(:users) do |t|
      t.datetime :created_on
      t.datetime :updated_on
    end.define_model

    assert_problems(<<~OUTPUT)
      add `NOT NULL` to users.created_on - timestamp columns are set automatically by Active Record and allowing NULL may lead to inconsistencies introduced by bulk operations
      add `NOT NULL` to users.updated_on - timestamp columns are set automatically by Active Record and allowing NULL may lead to inconsistencies introduced by bulk operations
    OUTPUT
  end
end
