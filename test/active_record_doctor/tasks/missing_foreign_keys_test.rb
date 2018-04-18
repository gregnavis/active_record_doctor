require 'test_helper'

require 'active_record_doctor/tasks/missing_foreign_keys'

class ActiveRecordDoctor::Tasks::MissingForeignKeysTest < ActiveSupport::TestCase
  def test_missing_foreign_key_is_reported
    Temping.create(:companies, temporary: false)
    Temping.create(:users, temporary: false) do
      with_columns do |t|
        t.references :company, foreign_key: false
      end
    end

    assert_equal({'users' => ['company_id']}, run_task)
  end

  def test_present_foreign_key_is_not_reported
    Temping.create(:companies, temporary: false)
    Temping.create(:users, temporary: false) do
      with_columns do |t|
        t.references :company, foreign_key: true
      end
    end

    assert_equal({}, run_task)
  end
end
