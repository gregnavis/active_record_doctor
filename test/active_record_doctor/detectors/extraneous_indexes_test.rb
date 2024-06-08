# frozen_string_literal: true

class ActiveRecordDoctor::Detectors::ExtraneousIndexesTest < Minitest::Test
  def test_index_on_primary_key_is_duplicate
    Context.create_table(:users) do |t|
      t.index :id
    end

    assert_problems(<<OUTPUT)
remove index_users_on_id from users - coincides with the primary key on the table
OUTPUT
  end

  def test_partial_index_on_primary_key
    skip("MySQL doesn't support partial indexes") if mysql?

    Context.create_table(:users) do |t|
      t.boolean :admin
      t.index :id, where: "admin"
    end

    refute_problems
  end

  def test_index_on_non_standard_primary_key
    Context.create_table(:profiles, primary_key: :user_id) do |t|
      t.index :user_id
    end

    assert_problems(<<OUTPUT)
remove index_profiles_on_user_id from profiles - coincides with the primary key on the table
OUTPUT
  end

  def test_non_unique_version_of_index_is_duplicate
    Context.create_table(:users) do |t|
      t.string :email
      t.index :email, unique: true, name: "unique_index_on_users_email"
    end

    # Rails 4.2 compatibility - can't be pulled into the block above.
    ActiveRecord::Base.connection.add_index :users, :email, name: "index_users_on_email"

    assert_problems(<<OUTPUT)
remove the index index_users_on_email from the table users - queries should be able to use the following index instead: unique_index_on_users_email
OUTPUT
  end

  def test_single_column_covered_by_unique_and_non_unique_multi_column_is_duplicate
    Context.create_table(:users) do |t|
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
remove the index index_users_on_last_name from the table users - queries should be able to use the following indices instead: index_users_on_last_name_and_first_name_and_email or unique_index_on_users_last_name_and_first_name
OUTPUT
  end

  def test_multi_column_covered_by_unique_and_non_unique_multi_column_is_duplicate
    Context.create_table(:users) do |t|
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
remove the index index_users_on_last_name_and_first_name from the table users - queries should be able to use the following indices instead: index_users_on_last_name_and_first_name_and_email or unique_index_on_users_last_name_and_first_name
OUTPUT
  end

  def test_unique_index_with_fewer_columns
    Context.create_table(:users) do |t|
      t.string :first_name
      t.string :last_name
      t.index :first_name, unique: true
      t.index [:last_name, :first_name], unique: true
    end

    assert_problems(<<OUTPUT)
remove the index index_users_on_last_name_and_first_name from the table users - queries should be able to use the following index instead: index_users_on_first_name
OUTPUT
  end

  def test_expression_index_not_covered_by_multicolumn_index
    skip("Expression indexes are not supported") if ActiveRecordDoctor::Utils.expression_indexes_unsupported?

    Context.create_table(:users) do |t|
      t.string :first_name
      t.string :email
      t.index "(lower(email))"
      t.index [:first_name, :email]
    end

    refute_problems
  end

  def test_unique_expression_index_not_covered_by_unique_multicolumn_index
    skip("Expression indexes are not supported") if ActiveRecordDoctor::Utils.expression_indexes_unsupported?

    Context.create_table(:users) do |t|
      t.string :first_name
      t.string :email
      t.index "(lower(email))", unique: true
      t.index [:first_name, :email], unique: true
    end

    refute_problems
  end

  def test_not_covered_by_different_index_type
    Context.create_table(:users) do |t|
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

    Context.create_table(:users) do |t|
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

    Context.create_table(:users) do |t|
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
      Context.create_table(:users) do |t|
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
remove the index index_user_initials_on_last_name from the table user_initials - queries should be able to use the following index instead: index_user_initials_on_last_name_and_first_name
OUTPUT
    ensure
      connection.execute("DROP MATERIALIZED VIEW user_initials")
    end
  end

  def test_include_index_covered_by_other_non_include_index
    skip("ActiveRecord < 7.1 doesn't support include indexes") if ActiveRecord::VERSION::STRING < "7.1"
    skip("Only PostgreSQL supports include indexes") unless postgresql?

    Context.create_table(:users) do |t|
      t.string :first_name
      t.string :last_name
      t.index [:last_name, :first_name]
      t.index :last_name, include: :first_name
    end

    assert_problems(<<OUTPUT)
remove the index index_users_on_last_name from the table users - queries should be able to use the following index instead: index_users_on_last_name_and_first_name
OUTPUT
  end

  def test_include_index_covered_by_other_include_index
    skip("ActiveRecord < 7.1 doesn't support include indexes") if ActiveRecord::VERSION::STRING < "7.1"
    skip("Only PostgreSQL supports include indexes") unless postgresql?

    Context.create_table(:users) do |t|
      t.string :first_name
      t.string :last_name
      t.integer :age
      t.index :last_name, include: [:age, :first_name], name: "index1_users_on_last_name"
      t.index :last_name, include: :first_name, name: "index2_users_on_last_name"
    end

    assert_problems(<<OUTPUT)
remove the index index2_users_on_last_name from the table users - queries should be able to use the following index instead: index1_users_on_last_name
OUTPUT
  end

  def test_include_index_not_covered_by_other_index
    skip("ActiveRecord < 7.1 doesn't support include indexes") if ActiveRecord::VERSION::STRING < "7.1"
    skip("Only PostgreSQL supports include indexes") unless postgresql?

    Context.create_table(:users) do |t|
      t.string :first_name
      t.string :last_name
      t.integer :age
      t.index [:first_name, :last_name]
      t.index :last_name, include: :first_name
    end

    refute_problems
  end

  def test_config_ignore_tables
    # The detector recognizes two kinds of errors and both must take
    # ignore_tables into account. We trigger those errors by indexing the
    # primary key (the first extraneous index) and then indexing email twice
    # (index2... is the other extraneous index).
    Context.create_table(:users) do |t|
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

  def test_config_ignore_tables_regexp
    Context.create_table(:users_tmp) do |t|
      t.index :id
    end

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :extraneous_indexes,
          ignore_tables: [/_tmp\\z/]
      end
    CONFIG

    refute_problems
  end

  def test_config_ignore_tables_string_ignores_exact_match
    Context.create_table(:users) do |t|
      t.index :id
    end

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :extraneous_indexes,
          ignore_tables: ["users_profiles"]
      end
    CONFIG

    assert_problems(<<OUTPUT)
remove index_users_on_id from users - coincides with the primary key on the table
OUTPUT
  end

  def test_config_global_ignore_tables
    Context.create_table(:users) do |t|
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
    Context.create_table(:users) do |t|
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
    Context.create_table(:users) do |t|
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

  def test_config_detector_ignore_indexes_regexp
    Context.create_table(:users) do |t|
      t.index :id
      t.string :email
      t.string :api_key

      t.index :email, name: "index_users_on_email"
      t.index [:email, :api_key], name: "index_users_on_email_and_api_key"
    end

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :extraneous_indexes,
          ignore_indexes: [/\\Aindex_users_/]
      end
    CONFIG

    refute_problems
  end
end
