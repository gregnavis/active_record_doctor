# frozen_string_literal: true

class ActiveRecordDoctor::Detectors::MismatchedForeignKeyTypeTest < Minitest::Test
  def test_mismatched_foreign_key_type_is_reported
    # MySQL does not allow foreign keys to have different type than paired primary keys
    return if mysql?

    create_table(:companies, id: :bigint)
    create_table(:users) do |t|
      t.references :company, foreign_key: true, type: :integer
    end

    assert_problems(<<OUTPUT)
users.company_id references a column of different type - foreign keys should be of the same type as the referenced column
OUTPUT
  end

  def test_matched_foreign_key_type_is_not_reported
    create_table(:companies)
    create_table(:users) do |t|
      t.references :company, foreign_key: true
    end

    refute_problems
  end
end
