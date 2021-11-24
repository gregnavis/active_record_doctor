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

    assert_problems(<<~OUTPUT)
      add a `presence` validator to ModelFactory::Models::User.name - it's NOT NULL but lacks a validator
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

  def test_not_null_column_is_not_reported_if_habtm_association
    create_table(:users).create_model do
      has_and_belongs_to_many :projects, class_name: "ModelFactory::Models::Project"
    end

    create_table(:projects_users) do |t|
      t.bigint :project_id, null: false
      t.bigint :user_id, null: false
    end

    create_table(:projects).create_model do
      has_and_belongs_to_many :users, class_name: "ModelFactory::Models::User"
    end

    refute_problems
  end

  def test_non_null_boolean_is_reported_if_nil_included
    create_table(:users) do |t|
      t.boolean :active, null: false
    end.create_model do
      validates :active, inclusion: { in: [nil, true, false] }
    end

    assert_problems(<<~OUTPUT)
      add a `presence` validator to ModelFactory::Models::User.active - it's NOT NULL but lacks a validator
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

    assert_problems(<<~OUTPUT)
      add a `presence` validator to ModelFactory::Models::User.active - it's NOT NULL but lacks a validator
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
    create_model(:User)

    refute_problems
  end

  def test_config_ignore_models
    create_table(:users) do |t|
      t.string :name, null: false
    end.create_model do
    end

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :missing_presence_validation,
          ignore_models: ["ModelFactory::Models::User"]
      end
    CONFIG

    refute_problems
  end

  def test_global_ignore_models
    create_table(:users) do |t|
      t.string :name, null: false
    end.create_model do
    end

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.global :ignore_models, ["ModelFactory::Models::User"]
      end
    CONFIG

    refute_problems
  end

  def test_config_ignore_attributes
    create_table(:users) do |t|
      t.string :name, null: false
    end.create_model do
    end

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :missing_presence_validation,
          ignore_attributes: ["ModelFactory::Models::User.name"]
      end
    CONFIG

    refute_problems
  end
end
