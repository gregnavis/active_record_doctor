class ActiveRecordDoctor::Tasks::ExtraneousIndexesTest < Minitest::Test
  def test_index_on_primary_key_is_duplicate
    Temping.create(:user, temporary: false) do
      with_columns do |t|
        t.index :id
      end
    end

    assert_result([['index_users_on_id', [:primary_key, 'users']]])
  end

  def test_non_unique_version_of_index_is_duplicate
    Temping.create(:user, temporary: false) do
      with_columns do |t|
        t.string :email
        t.index :email, name: 'index_users_on_email'
        t.index :email, unique: true, name: 'unique_index_on_users_email'
      end
    end

    assert_result([
      ['index_users_on_email', [:multi_column, 'unique_index_on_users_email']]
    ])
  end

  def test_single_column_covered_by_unique_and_non_unique_multi_column_is_duplicate
    Temping.create(:user, temporary: false) do
      with_columns do |t|
        t.string :first_name
        t.string :last_name
        t.string :email
        t.index [:last_name, :first_name, :email]
        t.index [:last_name, :first_name],
          unique: true,
          name: 'unique_index_on_users_last_name_and_first_name'
        t.index :last_name
      end
    end

    assert_result([
      [
        'index_users_on_last_name',
        [
          :multi_column,
          'index_users_on_last_name_and_first_name_and_email',
          'unique_index_on_users_last_name_and_first_name'
        ]
      ]
    ])
  end

  def test_multi_column_covered_by_unique_and_non_unique_multi_column_is_duplicate
    Temping.create(:user, temporary: false) do
      with_columns do |t|
        t.string :first_name
        t.string :last_name
        t.string :email
        t.index [:last_name, :first_name, :email]
        t.index [:last_name, :first_name],
          unique: true,
          name: 'unique_index_on_users_last_name_and_first_name'
        t.index [:last_name, :first_name]
      end
    end

    assert_result([
      [
        'index_users_on_last_name_and_first_name',
        [
          :multi_column,
          'index_users_on_last_name_and_first_name_and_email',
          'unique_index_on_users_last_name_and_first_name'
        ]
      ]
    ])
  end
end
