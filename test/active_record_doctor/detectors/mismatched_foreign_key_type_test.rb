# frozen_string_literal: true

class ActiveRecordDoctor::Detectors::MismatchedForeignKeyTypeTest < Minitest::Test
  def test_mismatched_foreign_key_type_is_reported
    # MySQL does not allow foreign keys to have different type than paired primary keys
    return if mysql?

    create_table(:companies, id: :bigint)
    create_table(:users) do |t|
      t.references :company, foreign_key: true, type: :integer
    end

    assert_problems(<<~OUTPUT)
      users.company_id references a column of different type - foreign keys should be of the same type as the referenced column
    OUTPUT
  end

  def test_matched_foreign_key_with_non_primary_key_type_is_not_reported
    # MySQL does not allow foreign keys to have different type than paired primary keys
    return if mysql?

    create_table(:companies, id: :bigint) do |t|
      t.integer :entity_id
      t.index [:entity_id], unique: true
    end
    create_table(:users) do |t|
      t.references :entity, foreign_key: false, type: :integer, index: false
      t.foreign_key :companies, column: :entity_id, primary_key: :entity_id
    end

    refute_problems
  end

  def test_matched_foreign_key_type_is_not_reported
    create_table(:companies)
    create_table(:users) do |t|
      t.references :company, foreign_key: true
    end

    refute_problems
  end

  def test_config_ignore_tables
    # MySQL does not allow foreign keys to have different type than paired primary keys
    return if mysql?

    create_table(:companies, id: :bigint)
    create_table(:users) do |t|
      t.references :company, foreign_key: true, type: :integer
    end

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :mismatched_foreign_key_type,
          ignore_tables: ["users"]
      end
    CONFIG

    refute_problems
  end

  def test_global_ignore_tables
    # MySQL does not allow foreign keys to have different type than paired primary keys
    return if mysql?

    create_table(:companies, id: :bigint)
    create_table(:users) do |t|
      t.references :company, foreign_key: true, type: :integer
    end

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.global :ignore_tables, ["users"]
      end
    CONFIG

    refute_problems
  end

  def test_config_ignore_columns
    # MySQL does not allow foreign keys to have different type than paired primary keys
    return if mysql?

    create_table(:companies, id: :bigint)
    create_table(:users) do |t|
      t.references :company, foreign_key: true, type: :integer
    end

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :mismatched_foreign_key_type,
          ignore_columns: ["users.company_id"]
      end
    CONFIG

    refute_problems
  end
end
