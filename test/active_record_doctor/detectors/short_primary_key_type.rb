# frozen_string_literal: true

class ActiveRecordDoctor::Detectors::ShortPrimaryKeyTypeTest < Minitest::Test
  def test_short_integer_primary_key_is_reported
    create_table(:companies, id: :integer)

    assert_problems(<<OUTPUT)
The following primary keys have a short integer type:
  companies id
OUTPUT
  end

  def test_long_integer_primary_key_is_not_reported
    create_table(:companies)
    create_table(:users, id: :bigserial)

    if ActiveRecord::VERSION::STRING >= "5.1"
      refute_problems
    else
      assert_problems(<<OUTPUT)
The following primary keys have a short integer type:
  companies id
OUTPUT
    end
  end
end
