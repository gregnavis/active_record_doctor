class ActiveRecordDoctor::Tasks::MissingForeignKeysTest < Minitest::Test
  def test_missing_foreign_key_is_reported
    create_table(:companies)
    create_table(:users) do |t|
      t.references :company, foreign_key: false
    end

    assert_equal({'users' => ['company_id']}, run_task)
  end

  def test_present_foreign_key_is_not_reported
    create_table(:companies)
    create_table(:users) do |t|
      t.references :company, foreign_key: true
    end

    assert_equal({}, run_task)
  end
end
