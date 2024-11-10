# frozen_string_literal: true

class ActiveRecordDoctor::Detectors::UnindexedDeletedAtTest < Minitest::Test
  def test_indexed_deleted_at_is_not_reported
    require_partial_indexes!

    Context.create_table(:users) do |t|
      t.string :first_name
      t.string :last_name
      t.datetime :deleted_at
      t.index [:first_name, :last_name],
        name: "index_profiles_on_first_name_and_last_name",
        where: "deleted_at IS NULL"
      t.index [:last_name],
        name: "index_deleted_profiles_on_last_name",
        where: "deleted_at IS NOT NULL"
    end

    refute_problems
  end

  def test_unindexed_deleted_at_is_reported
    require_partial_indexes!

    Context.create_table(:users) do |t|
      t.string :first_name
      t.string :last_name
      t.datetime :deleted_at
      t.index [:first_name, :last_name],
        name: "index_profiles_on_first_name_and_last_name"
    end

    assert_problems(<<~OUTPUT)
      consider adding `WHERE deleted_at IS NULL` or `WHERE deleted_at IS NOT NULL` to index_profiles_on_first_name_and_last_name - a partial index can speed lookups of soft-deletable models
    OUTPUT
  end

  def test_indexed_discarded_at_is_not_reported
    require_partial_indexes!

    Context.create_table(:users) do |t|
      t.string :first_name
      t.string :last_name
      t.datetime :discarded_at
      t.index [:first_name, :last_name],
        name: "index_profiles_on_first_name_and_last_name",
        where: "discarded_at IS NULL"
      t.index [:last_name],
        name: "index_discarded_profiles_on_last_name",
        where: "discarded_at IS NOT NULL"
    end

    refute_problems
  end

  def test_unindexed_discarded_at_is_reported
    require_partial_indexes!

    Context.create_table(:users) do |t|
      t.string :first_name
      t.string :last_name
      t.datetime :discarded_at
      t.index [:first_name, :last_name],
        name: "index_profiles_on_first_name_and_last_name"
    end

    assert_problems(<<~OUTPUT)
      consider adding `WHERE discarded_at IS NULL` or `WHERE discarded_at IS NOT NULL` to index_profiles_on_first_name_and_last_name - a partial index can speed lookups of soft-deletable models
    OUTPUT
  end

  def test_config_ignore_tables
    require_partial_indexes!

    Context.create_table(:users) do |t|
      t.string :first_name
      t.string :last_name
      t.datetime :discarded_at
      t.index [:first_name, :last_name],
        name: "index_profiles_on_first_name_and_last_name"
    end

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :unindexed_deleted_at,
          ignore_tables: ["users"]
      end
    CONFIG

    refute_problems
  end

  def test_global_ignore_tables
    require_partial_indexes!

    Context.create_table(:users) do |t|
      t.string :first_name
      t.string :last_name
      t.datetime :discarded_at
      t.index [:first_name, :last_name],
        name: "index_profiles_on_first_name_and_last_name"
    end

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.global :ignore_tables, ["users"]
      end
    CONFIG

    refute_problems
  end

  def test_config_ignore_columns
    require_partial_indexes!

    Context.create_table(:users) do |t|
      t.string :first_name
      t.string :last_name
      t.datetime :discarded_at
      t.index [:first_name, :last_name],
        name: "index_profiles_on_first_name_and_last_name"
    end

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :unindexed_deleted_at,
          ignore_columns: ["users.discarded_at"]
      end
    CONFIG

    refute_problems
  end

  def test_config_ignore_indexes
    require_partial_indexes!

    Context.create_table(:users) do |t|
      t.string :first_name
      t.string :last_name
      t.datetime :discarded_at
      t.index [:first_name, :last_name],
        name: "index_profiles_on_first_name_and_last_name"
    end

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :unindexed_deleted_at,
          ignore_indexes: ["index_profiles_on_first_name_and_last_name"]
      end
    CONFIG

    refute_problems
  end

  def test_config_column_names
    require_partial_indexes!

    Context.create_table(:users) do |t|
      t.string :first_name
      t.string :last_name
      t.datetime :obliverated_at
      t.index [:first_name, :last_name],
        name: "index_profiles_on_first_name_and_last_name"
    end

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :unindexed_deleted_at,
          column_names: ["obliverated_at"]
      end
    CONFIG

    assert_problems(<<~OUTPUT)
      consider adding `WHERE obliverated_at IS NULL` or `WHERE obliverated_at IS NOT NULL` to index_profiles_on_first_name_and_last_name - a partial index can speed lookups of soft-deletable models
    OUTPUT
  end
end
