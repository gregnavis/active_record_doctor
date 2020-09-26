class ActiveRecordDoctor::Tasks::UnindexedForeignKeysTest < Minitest::Test
  def test_unindexed_foreign_key_is_reported
    Temping.create(:companies, temporary: false)
    Temping.create(:users, temporary: false) do
      with_columns do |t|
        t.references :company, foreign_key: true, index: false
      end
    end

    assert_equal({'users' => ['company_id']}, run_task)
  end

  def test_indexed_foreign_key_is_not_reported
    Temping.create(:companies, temporary: false)
    Temping.create(:users, temporary: false) do
      with_columns do |t|
        t.references :company, foreign_key: true, index: true
      end
    end

    assert_equal({}, run_task)
  end
end
