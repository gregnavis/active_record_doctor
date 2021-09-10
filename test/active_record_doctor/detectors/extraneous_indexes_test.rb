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

  def test_non_unique_version_of_index_is_duplicate
    create_table(:users) do |t|
      t.string :email
      t.index :email, unique: true, name: "unique_index_on_users_email"
    end

    # Rails 4.2 compatibility - can't be pulled into the block above.
    ActiveRecord::Base.connection.add_index :users, :email, name: "index_users_on_email"

    assert_problems(<<OUTPUT)
remove index_users_on_email - can be replaced by unique_index_on_users_email
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
remove index_users_on_last_name - can be replaced by index_users_on_last_name_and_first_name_and_email or unique_index_on_users_last_name_and_first_name
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
remove index_users_on_last_name_and_first_name - can be replaced by index_users_on_last_name_and_first_name_and_email or unique_index_on_users_last_name_and_first_name
OUTPUT
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

    config_file(<<CONFIG)
ActiveRecordDoctor.configure do |config|
  config.detector :extraneous_indexes,
    ignore_tables: ["users"]
end
CONFIG

    refute_problems
  end

  def test_config_ignore_indexes
    create_table(:users) do |t|
      t.index :id
      t.string :email
      t.string :api_key

      t.index :email, name: "index_on_users_email"
      t.index [:email, :api_key], name: "index_on_users_email_and_api_key"
    end

    config_file(<<CONFIG)
ActiveRecordDoctor.configure do |config|
  config.detector :extraneous_indexes,
    ignore_indexes: ["index_users_on_id", "index_on_users_email"]
end
CONFIG

    refute_problems
  end
end
