# frozen_string_literal: true

class ActiveRecordDoctor::Detectors::MissingForeignKeysTest < Minitest::Test
  def test_missing_foreign_key_is_reported
    Context.create_table(:companies)
    Context.create_table(:users) do |t|
      t.references :company, foreign_key: false
    end

    assert_problems(<<~OUTPUT)
      create a foreign key on users.company_id - looks like an association without a foreign key constraint
    OUTPUT
  end

  def test_present_foreign_key_is_not_reported
    Context.create_table(:companies)
    Context.create_table(:users) do |t|
      t.references :company, foreign_key: true
    end

    refute_problems
  end

  def test_non_integer_missing_foreign_key_is_reported
    Context.create_table(:users) do |t|
      t.string :external_id
    end

    refute_problems
  end

  def test_uuid_missing_foreign_key_is_reported
    require_uuid_column_type!

    Context.create_table(:users) do |t|
      t.uuid :company_id
    end

    assert_problems(<<~OUTPUT)
      create a foreign key on users.company_id - looks like an association without a foreign key constraint
    OUTPUT
  end

  def test_destroy_async_is_not_reported
    Context.create_table(:companies).define_model do
      # We need an ActiveJob job defined to appease the ActiveRecord
      class_attribute :destroy_association_async_job, default: Class.new

      has_many :users, dependent: :destroy_async
    end

    Context.create_table(:users) do |t|
      t.references :company, foreign_key: false
    end.define_model

    refute_problems
  end

  def test_config_ignore_models
    Context.create_table(:companies)
    Context.create_table(:users) do |t|
      t.references :company, foreign_key: false
    end

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :missing_foreign_keys,
          ignore_tables: ["users"]
      end
    CONFIG

    refute_problems
  end

  def test_global_ignore_models
    Context.create_table(:companies)
    Context.create_table(:users) do |t|
      t.references :company, foreign_key: false
    end

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.global :ignore_tables, ["users"]
      end
    CONFIG

    refute_problems
  end

  def test_config_ignore_columns
    Context.create_table(:companies)
    Context.create_table(:users) do |t|
      t.references :company, foreign_key: false
    end

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :missing_foreign_keys,
          ignore_columns: ["users.company_id"]
      end
    CONFIG

    refute_problems
  end
end
