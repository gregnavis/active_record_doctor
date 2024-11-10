# frozen_string_literal: true

class ActiveRecordDoctor::Detectors::UnindexedForeignKeysTest < Minitest::Test
  def test_unindexed_foreign_key_is_reported
    require_non_indexed_foreign_keys!

    Context.create_table(:companies)
    Context.create_table(:users) do |t|
      t.references :company, foreign_key: true, index: false
    end

    assert_problems(<<~OUTPUT)
      add an index on users(company_id) - foreign keys are often used in database lookups and should be indexed for performance reasons
    OUTPUT
  end

  def test_unindexed_foreign_key_with_nonstandard_name_is_reported
    require_non_indexed_foreign_keys!

    Context.create_table(:companies)
    Context.create_table(:users) do |t|
      t.integer :company
      t.foreign_key :companies, column: :company
    end

    assert_problems(<<~OUTPUT)
      add an index on users(company) - foreign keys are often used in database lookups and should be indexed for performance reasons
    OUTPUT
  end

  def test_unindexed_polymorphic_foreign_key_is_reported
    Context.create_table(:notes) do |t|
      t.integer :notable_id
      t.string :notable_type
    end

    assert_problems(<<~OUTPUT)
      add an index on notes(notable_type, notable_id) - foreign keys are often used in database lookups and should be indexed for performance reasons
    OUTPUT
  end

  def test_indexed_polymorphic_foreign_key_is_not_reported
    Context.create_table(:notes) do |t|
      t.string :title
      t.integer :notable_id
      t.string :notable_type

      # Includes additional column except `notable`
      t.index [:notable_type, :notable_id, :title]
    end

    refute_problems
  end

  def test_indexed_foreign_key_is_not_reported
    Context.create_table(:companies)
    Context.create_table(:users) do |t|
      t.references :company, foreign_key: true, index: true
    end

    refute_problems
  end

  def test_foreign_key_is_a_primary_key_not_reported
    Context.create_table(:parents)
    Context.create_table(:children, primary_key: :parent_id)
    ActiveRecord::Base.connection.add_foreign_key(:children, :parents)

    refute_problems
  end

  def test_config_ignore_tables
    require_non_indexed_foreign_keys!

    Context.create_table(:companies)
    Context.create_table(:users) do |t|
      t.references :company, foreign_key: true, index: false
    end

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :unindexed_foreign_keys,
          ignore_tables: ["users"]
      end
    CONFIG

    refute_problems
  end

  def test_config_ignore_tables_regexp
    require_non_indexed_foreign_keys!

    Context.create_table(:companies)
    Context.create_table(:users_tmp) do |t|
      t.references :company, foreign_key: true, index: false
    end

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :unindexed_foreign_keys,
          ignore_tables: [/_tmp\\z/]
      end
    CONFIG

    refute_problems
  end

  def test_global_ignore_tables
    require_non_indexed_foreign_keys!

    Context.create_table(:companies)
    Context.create_table(:users) do |t|
      t.references :company, foreign_key: true, index: false
    end

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.global :ignore_tables, ["users"]
      end
    CONFIG

    refute_problems
  end

  def test_config_ignore_columns
    require_non_indexed_foreign_keys!

    Context.create_table(:companies)
    Context.create_table(:users) do |t|
      t.references :company, foreign_key: true, index: false
    end

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :unindexed_foreign_keys,
          ignore_columns: ["users.company_id"]
      end
    CONFIG

    refute_problems
  end

  def test_config_ignore_columns_regexp
    require_non_indexed_foreign_keys!

    Context.create_table(:companies)
    Context.create_table(:users) do |t|
      t.integer :company_id_tmp
      t.foreign_key :companies, column: :company_id_tmp, index: false
    end

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :unindexed_foreign_keys,
          ignore_columns: [/_tmp\\z/]
      end
    CONFIG

    refute_problems
  end
end
