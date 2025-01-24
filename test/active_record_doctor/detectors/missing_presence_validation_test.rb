# frozen_string_literal: true

class ActiveRecordDoctor::Detectors::MissingPresenceValidationTest < Minitest::Test
  def test_null_column_is_not_reported_if_validation_absent
    Context.create_table(:users) do |t|
      t.string :name
    end.define_model do
    end

    refute_problems
  end

  def test_non_null_column_is_reported_if_validation_absent
    Context.create_table(:users) do |t|
      t.string :name, null: false
    end.define_model do
    end

    assert_problems(<<~OUTPUT)
      add a `presence` validator to Context::User.name - it's NOT NULL but lacks a validator
    OUTPUT
  end

  def test_non_null_column_is_not_reported_if_validation_present
    Context.create_table(:users) do |t|
      t.string :name, null: false
    end.define_model do
      validates :name, presence: true
    end

    refute_problems
  end

  def test_non_null_column_is_not_reported_if_association_validation_present
    Context.create_table(:companies).define_model
    Context.create_table(:users) do |t|
      t.references :company, null: false
    end.define_model do
      belongs_to :company, required: true
    end

    refute_problems
  end

  def test_not_null_column_is_not_reported_if_habtm_association
    Context.create_table(:users).define_model do
      has_and_belongs_to_many :projects, class_name: "Context::Project"
    end

    Context.create_table(:projects_users) do |t|
      t.bigint :project_id, null: false
      t.bigint :user_id, null: false
    end

    Context.create_table(:projects).define_model do
      has_and_belongs_to_many :users, class_name: "Context::User"
    end

    refute_problems
  end

  def test_non_null_boolean_is_reported_if_nil_included
    Context.create_table(:users) do |t|
      t.boolean :active, null: false
    end.define_model do
      validates :active, inclusion: { in: [nil, true, false] }
    end

    assert_problems(<<~OUTPUT)
      add a `presence` validator to Context::User.active - it's NOT NULL but lacks a validator
    OUTPUT
  end

  def test_non_null_boolean_is_not_reported_if_nil_not_included
    Context.create_table(:users) do |t|
      t.boolean :active, null: false
    end.define_model do
      validates :active, inclusion: { in: [true, false] }
    end

    refute_problems
  end

  def test_non_null_boolean_is_not_reported_if_nil_excluded
    Context.create_table(:users) do |t|
      t.boolean :active, null: false
    end.define_model do
      validates :active, exclusion: { in: [nil] }
    end

    refute_problems
  end

  def test_non_null_boolean_is_not_reported_if_exclusion_is_proc
    Context.create_table(:users) do |t|
      t.boolean :active, null: false
    end.define_model do
      validates :active, exclusion: { in: ->(_user) { [nil] } }
    end

    refute_problems
  end

  def test_non_null_boolean_is_not_reported_if_inclusion_is_proc
    Context.create_table(:users) do |t|
      t.boolean :active, null: false
    end.define_model do
      validates :active, inclusion: { in: ->(_user) { [true, false] } }
    end

    refute_problems
  end

  def test_non_null_boolean_is_reported_if_nil_not_excluded
    Context.create_table(:users) do |t|
      t.boolean :active, null: false
    end.define_model do
      validates :active, exclusion: { in: [false] }
    end

    assert_problems(<<~OUTPUT)
      add a `presence` validator to Context::User.active - it's NOT NULL but lacks a validator
    OUTPUT
  end

  def test_timestamps_are_not_reported
    Context.create_table(:users) do |t|
      # Create created_at/updated_at timestamps.
      t.timestamps null: false

      # Rails also supports created_on/updated_on. We used datetime, which is
      # what the timestamps method users under the hood, to avoid default value
      # errors in some MySQL versions when using t.timestamp.
      t.datetime :created_on, null: false
      t.datetime :updated_on, null: false
    end.define_model do
    end

    refute_problems
  end

  def test_counter_caches_are_not_reported
    Context.create_table(:companies) do |t|
      t.integer :users_count, default: 0, null: false
    end.define_model do
      has_many :users
    end

    Context.create_table(:users) do |t|
      t.integer :company_id
    end.define_model do
      belongs_to :company, counter_cache: true
    end

    refute_problems
  end

  def test_counter_caches_with_custom_names_are_not_reported
    Context.create_table(:companies) do |t|
      t.integer :custom_users_count, default: 0, null: false
    end.define_model do
      has_many :users, counter_cache: :custom_users_count
    end

    Context.create_table(:users) do |t|
      t.integer :company_id
    end.define_model do
      belongs_to :company, counter_cache: :custom_users_count
    end
  end

  def test_composite_primary_key_is_not_reported
    require_composite_primary_keys!

    Context.create_table(:users, primary_key: [:company_id, :id]) do |t|
      t.bigint :company_id
      t.bigint :id
    end.define_model

    refute_problems
  end

  def test_models_with_non_existent_tables_are_skipped
    Context.define_model(:User)

    refute_problems
  end

  def test_not_null_check_constraint
    Context.create_table(:users) do |t|
      if !sqlite?
        t.string :name
      end
    end.define_model

    if sqlite?
      ActiveRecord::Base.connection.execute(<<-SQL)
        ALTER TABLE users ADD COLUMN name VARCHAR CONSTRAINT name_not_null CHECK (name IS NOT NULL)
      SQL
    else
      ActiveRecord::Base.connection.execute(<<-SQL)
        ALTER TABLE users ADD CONSTRAINT name_not_null CHECK (name IS NOT NULL)
      SQL
    end

    assert_problems(<<~OUTPUT)
      add a `presence` validator to Context::User.name - it's NOT NULL but lacks a validator
    OUTPUT
  end

  def test_abstract_class
    Context.define_model(:ApplicationRecord) do
      self.abstract_class = true
    end

    refute_problems
  end

  def test_config_ignore_models
    Context.create_table(:users) do |t|
      t.string :name, null: false
    end.define_model do
    end

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :missing_presence_validation,
          ignore_models: ["Context::User"]
      end
    CONFIG

    refute_problems
  end

  def test_global_ignore_models
    Context.create_table(:users) do |t|
      t.string :name, null: false
    end.define_model do
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
      t.string :name, null: false
    end.define_model do
    end

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :missing_presence_validation,
          ignore_attributes: ["Context::User.name"]
      end
    CONFIG

    refute_problems
  end

  def test_config_ignore_columns_with_default_columns_are_not_ignored_by_default
    Context.create_table(:users) do |t|
      t.integer :posts_count, null: false, default: 0
    end.define_model

    assert_problems(<<~OUTPUT)
      add a `presence` validator to Context::User.posts_count - it's NOT NULL but lacks a validator
    OUTPUT
  end

  def test_config_ignore_columns_with_default
    Context.create_table(:users) do |t|
      t.integer :posts_count, null: false, default: 0
    end.define_model

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :missing_presence_validation,
          ignore_columns_with_default: true
      end
    CONFIG

    refute_problems
  end
end
