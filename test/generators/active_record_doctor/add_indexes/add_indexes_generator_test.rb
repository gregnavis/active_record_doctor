# frozen_string_literal: true

require "rails/generators"

require "generators/active_record_doctor/add_indexes/add_indexes_generator"

class ActiveRecordDoctor::AddIndexesGeneratorTest < Minitest::Test
  TIMESTAMP = Time.new(2021, 2, 1, 13, 15, 30)

  def test_create_migrations
    create_table(:notes) do |t|
      t.integer :notable_id, null: false
      t.string :notable_type, null: false
    end
    create_table(:users) do |t|
      t.integer :organization_id, null: false
      t.integer :account_id, null: false
    end
    create_table(:organizations) do |t|
      t.integer :owner_id
    end

    Dir.mktmpdir do |dir|
      Dir.chdir(dir)

      path = File.join(dir, "indexes.txt")
      File.write(path, <<~INDEXES)
        add an index on users(organization_id) - foreign keys are often used in database lookups and should be indexed for performance reasons
        add an index on users(account_id) - foreign keys are often used in database lookups and should be indexed for performance reasons
        add an index on organizations(owner_id) - foreign keys are often used in database lookups and should be indexed for performance reasons
        add an index on notes(notable_type, notable_id) - foreign keys are often used in database lookups and should be indexed for performance reasons
      INDEXES

      capture_io do
        Time.stub(:now, TIMESTAMP) do
          ActiveRecordDoctor::AddIndexesGenerator.start([path])

          load(File.join("db", "migrate", "20210201131530_index_foreign_keys_in_users.rb"))
          IndexForeignKeysInUsers.migrate(:up)

          load(File.join("db", "migrate", "20210201131531_index_foreign_keys_in_organizations.rb"))
          IndexForeignKeysInOrganizations.migrate(:up)

          load(File.join("db", "migrate", "20210201131532_index_foreign_keys_in_notes.rb"))
          IndexForeignKeysInNotes.migrate(:up)

          ::Object.send(:remove_const, :IndexForeignKeysInUsers)
          ::Object.send(:remove_const, :IndexForeignKeysInOrganizations)
          ::Object.send(:remove_const, :IndexForeignKeysInNotes)
        end
      end

      assert_indexes([
        ["notes", ["notable_type", "notable_id"]],
        ["users", ["organization_id"]],
        ["users", ["account_id"]],
        ["organizations", ["owner_id"]]
      ])

      assert_equal(5, Dir.entries("./db/migrate").size)
    end
  end

  def test_create_migrations_raises_when_malformed_inpout
    Tempfile.create do |file|
      file.write(<<~INDEXES)
        add an index on users() - foreign keys are often used in database lookups and should be indexed for performance reasons
      INDEXES
      file.flush

      assert_raises(RuntimeError) do
        capture_io do
          ActiveRecordDoctor::AddIndexesGenerator.start([file.path])
        end
      end
    end
  end

  def test_create_migrations_skips_blank_lines
    Dir.mktmpdir do |dir|
      Dir.chdir(dir)

      path = File.join(dir, "indexes.txt")
      File.write(path, "\n")

      capture_io do
        Time.stub(:now, TIMESTAMP) do
          # Not raising an exception is considered success.
          ActiveRecordDoctor::AddIndexesGenerator.start([path])
        end
      end
    end
  end

  def test_create_migrations_truncates_long_index_names
    # Both the table and column names must be quite long. Otherwise, the
    # we might reach table or column name length limits and fail to generate an
    # index name that's long enough.
    create_table(:organizations_migrated_from_legacy_app) do |t|
      t.integer :legacy_owner_id_compatible_with_v1_to_v8
    end

    Dir.mktmpdir do |dir|
      Dir.chdir(dir)

      path = File.join(dir, "indexes.txt")
      File.write(path, <<~INDEXES)
        add an index on organizations_migrated_from_legacy_app(legacy_owner_id_compatible_with_v1_to_v8) - foreign keys are often used in database lookups and should be indexed for performance reasons
      INDEXES

      capture_io do
        Time.stub(:now, TIMESTAMP) do
          # If no exceptions are raised then we consider this to be a success.
          ActiveRecordDoctor::AddIndexesGenerator.start([path])

          load(File.join(
            "db",
            "migrate",
            "20210201131530_index_foreign_keys_in_organizations_migrated_from_legacy_app.rb"
          ))
          ::IndexForeignKeysInOrganizationsMigratedFromLegacyApp.migrate(:up)

          ::Object.send(:remove_const, :IndexForeignKeysInOrganizationsMigratedFromLegacyApp)
        end
      end
    end
  end

  private

  def assert_indexes(expected_indexes)
    actual_indexes =
      ActiveRecord::Base.connection.tables.map do |table|
        ActiveRecord::Base.connection.indexes(table).map do |index|
          [index.table, index.columns]
        end
      end.flatten(1)

    assert_equal(expected_indexes.sort, actual_indexes.sort)
  end
end
