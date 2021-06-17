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
end
