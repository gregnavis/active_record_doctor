# frozen_string_literal: true

class ActiveRecordDoctor::Detectors::UnindexedForeignKeysTest < Minitest::Test
  def test_unindexed_foreign_key_is_reported
    create_table(:companies)
    create_table(:users) do |t|
      t.references :company, foreign_key: true, index: false
    end

    assert_equal({ "users" => ["company_id"] }, run_detector)
  end

  def test_indexed_foreign_key_is_not_reported
    create_table(:companies)
    create_table(:users) do |t|
      t.references :company, foreign_key: true, index: true
    end

    assert_equal({}, run_detector)
  end
end
