# frozen_string_literal: true

class ActiveRecordDoctor::Detectors::MismatchedForeignKeyTypeTest < Minitest::Test
  def test_mismatched_foreign_key_type_is_reported
    require_foreign_keys_of_different_type!

    Context.create_table(:companies, id: :smallint)
    Context.create_table(:users) do |t|
      t.references :company, foreign_key: true, type: :integer
    end

    if sqlite?
      assert_problems(<<~OUTPUT)
        users.company_id is a foreign key of type INTEGER and references companies.id of type smallint - foreign keys should be of the same type as the referenced column
      OUTPUT
    else
      assert_problems(<<~OUTPUT)
        users.company_id is a foreign key of type integer and references companies.id of type smallint - foreign keys should be of the same type as the referenced column
      OUTPUT
    end
  end

  def test_matched_foreign_key_type_is_not_reported
    Context.create_table(:companies)
    Context.create_table(:users) do |t|
      t.references :company, foreign_key: true
    end

    refute_problems
  end

  def test_mismatched_foreign_key_with_non_primary_key_type_is_reported
    require_foreign_keys_of_different_type!

    Context.create_table(:companies, id: :bigint) do |t|
      t.string :code
      t.index :code, unique: true
    end
    Context.create_table(:users) do |t|
      t.text :code
      t.foreign_key :companies, table: :companies, column: :code, primary_key: :code
    end

    if sqlite?
      assert_problems(<<~OUTPUT)
        users.code is a foreign key of type TEXT and references companies.code of type varchar - foreign keys should be of the same type as the referenced column
      OUTPUT
    else
      assert_problems(<<~OUTPUT)
        users.code is a foreign key of type text and references companies.code of type character varying - foreign keys should be of the same type as the referenced column
      OUTPUT
    end
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
    require_foreign_keys_of_different_type!

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
    require_foreign_keys_of_different_type!

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
    require_foreign_keys_of_different_type!

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
