# frozen_string_literal: true

class ActiveRecordDoctor::Detectors::UnindexedForeignKeysTest < Minitest::Test
  def test_unindexed_foreign_key_is_reported
    skip("MySQL always indexes foreign keys") if mysql?

    create_table(:companies)
    create_table(:users) do |t|
      t.references :company, foreign_key: true, index: false
    end

    assert_problems(<<OUTPUT)
add an index on users.company_id - foreign keys are often used in database lookups and should be indexed for performance reasons
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
