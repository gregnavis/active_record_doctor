require 'test_helper'

require 'active_record_doctor/tasks/missing_presence_validation'

class ActiveRecordDoctor::Tasks::MissingPresenceValidationTest < ActiveSupport::TestCase
  def test_null_column_is_not_reported_if_validation_absent
    Temping.create(:users, temporary: false) do
      with_columns do |t|
        t.string :name
      end
    end

    assert_equal({}, run_task)
  end

  def test_non_null_column_is_reported_if_validation_absent
    Temping.create(:users, temporary: false) do
      with_columns do |t|
        t.string :name, null: false
      end
    end

    assert_equal({ 'User' => ['name'] }, run_task)
  end

  def test_non_null_column_is_not_reported_if_validation_present
    Temping.create(:users, temporary: false) do
      validates :name, presence: true

      with_columns do |t|
        t.string :name, null: false
      end
    end

    assert_equal({}, run_task)
  end

  def test_timestamps_are_not_reported
    Temping.create(:users, temporary: false) do
      validates :name, presence: true

      with_columns do |t|
        t.timestamps null: false
      end
    end

    assert_equal({}, run_task)
  end
end
