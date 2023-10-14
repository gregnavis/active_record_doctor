# frozen_string_literal: true

class ActiveRecordDoctor::Detectors::MismatchedForeignKeyTypeTest < Minitest::Test
  def test_mismatched_foreign_key_type_is_reported
    # MySQL does not allow foreign keys to have different type than paired primary keys
    return if mysql?

    Context.create_table(:companies, id: :bigint)
    Context.create_table(:users) do |t|
      t.references :company, foreign_key: true, type: :integer
    end

    assert_problems(<<~OUTPUT)
      users.company_id is a foreign key of type integer and references companies.id of type bigint - foreign keys should be of the same type as the referenced column
    OUTPUT
  end

  def test_matched_foreign_key_type_is_not_reported
    Context.create_table(:companies)
    Context.create_table(:users) do |t|
      t.references :company, foreign_key: true
    end

    refute_problems
  end

  def test_mismatched_foreign_key_with_non_primary_key_type_is_reported
    # MySQL does not allow foreign keys to have different type than paired primary keys
    return if mysql?

    Context.create_table(:companies, id: :bigint) do |t|
      t.string :code
      t.index :code, unique: true
    end
    Context.create_table(:users) do |t|
      t.text :code
      t.foreign_key :companies, table: :companies, column: :code, primary_key: :code
    end

    assert_problems(<<~OUTPUT)
      users.code is a foreign key of type text and references companies.code of type character varying - foreign keys should be of the same type as the referenced column
    OUTPUT
  end

  def test_matched_foreign_key_with_non_primary_key_type_is_not_reported
    # MySQL does not allow foreign keys to have different type than paired primary keys
    return if mysql?

    Context.create_table(:companies, id: :bigint) do |t|
      t.string :code
      t.index :code, unique: true
    end
    Context.create_table(:users) do |t|
      t.string :code
      t.foreign_key :companies, table: :companies, column: :code, primary_key: :code
    end

    refute_problems
  end

  def test_config_ignore_tables
    # MySQL does not allow foreign keys to have different type than paired primary keys
    return if mysql?

    Context.create_table(:companies, id: :bigint)
    Context.create_table(:users) do |t|
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

    Context.create_table(:companies, id: :bigint)
    Context.create_table(:users) do |t|
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

    Context.create_table(:companies, id: :bigint)
    Context.create_table(:users) do |t|
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
