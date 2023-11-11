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

  def test_enums_with_default_are_not_reported
    skip unless ActiveRecordDoctor::Utils.attributes_api_supported?
    skip("ActiveRecord < 6.1 does not support enums with defaults") if ActiveRecord::VERSION::STRING < "6.1"

    Context.create_table(:users) do |t|
      t.string :role, null: false
    end.define_model do
      if ActiveRecord::VERSION::MAJOR >= 7
        # New syntax.
        enum :role, ["regular", "admin"], default: "regular"
      else
        enum role: ["regular", "admin"], _default: "regular"
      end
    end

    refute_problems
  end

  def test_custom_attributes_with_default_are_not_reported
    skip unless ActiveRecordDoctor::Utils.attributes_api_supported?

    Context.create_table(:users) do |t|
      t.string :role, null: false
    end.define_model do
      attribute :role, :string, default: "regular"

      if ActiveRecord::VERSION::MAJOR <= 5
        # Attributes are defined lazily after the schema loads,
        # so we need to load it manually.
        load_schema
      end
    end

    refute_problems
  end

  def test_models_with_non_existent_tables_are_skipped
    Context.define_model(:User)

    refute_problems
  end

  def test_not_null_check_constraint
    skip unless postgresql?

    Context.create_table(:users) do |t|
      t.string :name
    end.define_model

    ActiveRecord::Base.connection.execute(<<-SQL)
      ALTER TABLE users ADD CONSTRAINT name_not_null CHECK (name IS NOT NULL)
    SQL

    assert_problems(<<~OUTPUT)
      add a `presence` validator to Context::User.name - it's NOT NULL but lacks a validator
    OUTPUT
  end

  def test_not_null_check_constraint_not_valid
    skip unless postgresql?

    Context.create_table(:users) do |t|
      t.string :name
    end.define_model

    ActiveRecord::Base.connection.execute(<<-SQL)
      ALTER TABLE users ADD CONSTRAINT name_not_null CHECK (name IS NOT NULL) NOT VALID
    SQL

    refute_problems
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
end
