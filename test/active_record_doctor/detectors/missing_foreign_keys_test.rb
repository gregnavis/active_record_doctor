# frozen_string_literal: true

class ActiveRecordDoctor::Detectors::MissingForeignKeysTest < Minitest::Test
  def test_missing_foreign_key_is_reported
    create_table(:companies)
    create_table(:users) do |t|
      t.references :company, foreign_key: false
    end

    assert_success(<<OUTPUT)
The following columns lack a foreign key constraint:
  users company_id
OUTPUT
  end

  def test_present_foreign_key_is_not_reported
    create_table(:companies)
    create_table(:users) do |t|
      t.references :company, foreign_key: true
    end

    assert_success("")
  end
end
