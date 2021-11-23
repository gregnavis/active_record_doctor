# frozen_string_literal: true

require "rails/generators"

require "generators/active_record_doctor/add_indexes/add_indexes_generator"

class ActiveRecordDoctor::AddIndexesGeneratorTest < Minitest::Test
  TIMESTAMP = Time.new(2021, 2, 1, 13, 15, 30)

  def test_create_migrations
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
        users organization_id account_id
        organizations owner_id
      INDEXES

      capture_io do
        Time.stub(:now, TIMESTAMP) do
          ActiveRecordDoctor::AddIndexesGenerator.start([path])

          load(File.join("db", "migrate", "20210201131530_index_foreign_keys_in_users.rb"))
          IndexForeignKeysInUsers.migrate(:up)

          load(File.join("db", "migrate", "20210201131531_index_foreign_keys_in_organizations.rb"))
          IndexForeignKeysInOrganizations.migrate(:up)

          ::Object.send(:remove_const, :IndexForeignKeysInUsers)
          ::Object.send(:remove_const, :IndexForeignKeysInOrganizations)
        end
      end

      assert_indexes([
        ["users", ["organization_id"]],
        ["users", ["account_id"]],
        ["organizations", ["owner_id"]]
      ])

      assert_equal(4, Dir.entries("./db/migrate").size)
    end
  end

  def test_create_migrations_raises_when_table_name_missing
    Tempfile.create do |file|
      file.write(" organization_id")
      file.flush

      assert_raises(RuntimeError) do
        capture_io do
          ActiveRecordDoctor::AddIndexesGenerator.start([file.path])
        end
      end
    end
  end

  def test_create_migrations_raises_when_columns_missing
    Tempfile.create do |file|
      file.write("users")
      file.flush

      assert_raises(RuntimeError) do
        capture_io do
          ActiveRecordDoctor::AddIndexesGenerator.start([file.path])
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
