# frozen_string_literal: true

class ActiveRecordDoctor::Detectors::UnindexedForeignKeysTest < Minitest::Test
  def test_unindexed_foreign_key_is_reported
    skip("MySQL always indexes foreign keys") if mysql?

    create_table(:companies)
    create_table(:users) do |t|
      t.references :company, foreign_key: true, index: false
    end

    assert_problems(<<OUTPUT)
The following foreign keys should be indexed for performance reasons:
  users company_id
OUTPUT
  end

  def test_indexed_foreign_key_is_not_reported
    create_table(:companies)
    create_table(:users) do |t|
      t.references :company, foreign_key: true, index: true
    end

    refute_problems
  end
end
