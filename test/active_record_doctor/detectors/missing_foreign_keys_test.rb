# frozen_string_literal: true

class ActiveRecordDoctor::Detectors::MissingForeignKeysTest < Minitest::Test
  def test_missing_foreign_key_is_reported
    create_table(:companies)
    create_table(:users) do |t|
      t.references :company, foreign_key: false
    end

    assert_problems(<<OUTPUT)
create a foreign key on users.company_id - looks like an association without a foreign key constraint
OUTPUT
  end

  def test_present_foreign_key_is_not_reported
    create_table(:companies)
    create_table(:users) do |t|
      t.references :company, foreign_key: true
    end

    refute_problems
  end
end
