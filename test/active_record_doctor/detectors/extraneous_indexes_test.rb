# frozen_string_literal: true

class ActiveRecordDoctor::Detectors::ExtraneousIndexesTest < Minitest::Test
  def test_index_on_primary_key_is_duplicate
    create_table(:users) do |t|
      t.index :id
    end

    assert_problems(<<OUTPUT)
remove index_users_on_id - coincides with the primary key on the table
OUTPUT
  end

  def test_partial_index_on_primary_key
    skip("MySQL doesn't support partial indexes") if mysql?

    create_table(:users) do |t|
      t.boolean :admin
      t.index :id, where: "admin"
    end

    refute_problems
  end

  def test_index_on_non_standard_primary_key
    create_table(:profiles, primary_key: :user_id) do |t|
      t.index :user_id
    end

    assert_problems(<<OUTPUT)
remove index_profiles_on_user_id - coincides with the primary key on the table
OUTPUT
  end

  def test_non_unique_version_of_index_is_duplicate
    create_table(:users) do |t|
      t.string :email
      t.index :email, unique: true, name: "unique_index_on_users_email"
    end

    # Rails 4.2 compatibility - can't be pulled into the block above.
    ActiveRecord::Base.connection.add_index :users, :email, name: "index_users_on_email"

    assert_problems(<<OUTPUT)
remove index_users_on_email - queries should be able to use the following index instead: unique_index_on_users_email
OUTPUT
  end

  def test_single_column_covered_by_unique_and_non_unique_multi_column_is_duplicate
    create_table(:users) do |t|
      t.string :first_name
      t.string :last_name
      t.string :email
      t.index [:last_name, :first_name, :email]
      t.index [:last_name, :first_name],
        unique: true,
        name: "unique_index_on_users_last_name_and_first_name"
      t.index :last_name
    end

    assert_problems(<<OUTPUT)
remove index_users_on_last_name - queries should be able to use the following indices instead: index_users_on_last_name_and_first_name_and_email or unique_index_on_users_last_name_and_first_name
OUTPUT
  end

  def test_multi_column_covered_by_unique_and_non_unique_multi_column_is_duplicate
    create_table(:users) do |t|
      t.string :first_name
      t.string :last_name
      t.string :email
      t.index [:last_name, :first_name, :email]
      t.index [:last_name, :first_name],
        unique: true,
        name: "unique_index_on_users_last_name_and_first_name"
    end

    # Rails 4.2 compatibility - can't be pulled into the block above.
    ActiveRecord::Base.connection.add_index :users, [:last_name, :first_name]

    assert_problems(<<OUTPUT)
remove index_users_on_last_name_and_first_name - queries should be able to use the following indices instead: index_users_on_last_name_and_first_name_and_email or unique_index_on_users_last_name_and_first_name
OUTPUT
  end

  def test_unique_index_with_fewer_columns
    create_table(:users) do |t|
      t.string :first_name
      t.string :last_name
      t.index :first_name, unique: true
      t.index [:last_name, :first_name], unique: true
    end

    assert_problems(<<OUTPUT)
remove index_users_on_last_name_and_first_name - queries should be able to use the following index instead: index_users_on_first_name
OUTPUT
  end

  def test_not_covered_by_different_index_type
    create_table(:users) do |t|
      t.string :first_name
      t.string :last_name
      t.index [:last_name, :first_name], using: :btree

      if mysql?
        t.index :last_name, type: :fulltext
      else
        t.index :last_name, using: :hash
      end
    end

    refute_problems
  end

  def test_not_covered_by_partial_index
    skip("MySQL doesn't support partial indexes") if mysql?

    create_table(:users) do |t|
      t.string :first_name
      t.string :last_name
      t.boolean :active
      t.index [:last_name, :first_name], where: "active"
      t.index :last_name
    end

    refute_problems
  end

  def test_not_covered_with_different_opclasses
    skip("ActiveRecord < 5.2 doesn't support operator classes") if ActiveRecord::VERSION::STRING < "5.2"
    skip("MySQL doesn't support operator classes") if mysql?

    create_table(:users) do |t|
      t.string :first_name
      t.string :last_name
      t.index [:last_name, :first_name], opclass: :varchar_pattern_ops
      t.index :last_name
    end

    refute_problems
  end

  def test_single_column_covered_by_multi_column_on_materialized_view_is_duplicate
    skip("Only PostgreSQL supports materialized views") unless postgresql?

    begin
      create_table(:users) do |t|
        t.string :first_name
        t.string :last_name
        t.integer :age
      end

      connection = ActiveRecord::Base.connection
      connection.execute(<<-SQL)
        CREATE MATERIALIZED VIEW user_initials AS
          SELECT first_name, last_name FROM users
      SQL

      connection.add_index(:user_initials, [:last_name, :first_name])
      connection.add_index(:user_initials, :last_name)

      assert_problems(<<OUTPUT)
remove index_user_initials_on_last_name - queries should be able to use the following index instead: index_user_initials_on_last_name_and_first_name
OUTPUT
    ensure
      connection.execute("DROP MATERIALIZED VIEW user_initials")
    end
  end

  def test_config_ignore_tables
    # The detector recognizes two kinds of errors and both must take
    # ignore_tables into account. We trigger those errors by indexing the
    # primary key (the first extraneous index) and then indexing email twice
    # (index2... is the other extraneous index).
    create_table(:users) do |t|
      t.index :id
      t.string :email

      t.index :email, name: "index1_on_users_email"
      t.index :email, name: "index2_on_users_email"
    end

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :extraneous_indexes,
          ignore_tables: ["users"]
      end
    CONFIG

    refute_problems
  end

  def test_config_global_ignore_tables
    create_table(:users) do |t|
      t.index :id
      t.string :email

      t.index :email, name: "index1_on_users_email"
      t.index :email, name: "index2_on_users_email"
    end

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.global :ignore_tables, ["users"]
      end
    CONFIG

    refute_problems
  end

  def test_config_global_ignore_indexes
    create_table(:users) do |t|
      t.index :id
      t.string :email

      t.index :email, name: "index1_on_users_email"
      t.index :email, name: "index2_on_users_email"
    end

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.global :ignore_indexes, [
          "index1_on_users_email",
          "index2_on_users_email",
          "index_users_on_id",
        ]
      end
    CONFIG

    refute_problems
  end

  def test_config_detector_ignore_indexes
    create_table(:users) do |t|
      t.index :id
      t.string :email
      t.string :api_key

      t.index :email, name: "index_on_users_email"
      t.index [:email, :api_key], name: "index_on_users_email_and_api_key"
    end

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :extraneous_indexes,
          ignore_indexes: ["index_users_on_id", "index_on_users_email"]
      end
    CONFIG

    refute_problems
  end
end
