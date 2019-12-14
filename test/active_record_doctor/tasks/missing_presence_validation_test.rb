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

  def test_non_null_column_is_not_reported_if_association_validation_present
    Temping.create(:companies, temporary: false)
    Temping.create(:users, temporary: false) do
      belongs_to :company, required: true

      with_columns do |t|
        t.references :company, null: false
      end
    end

    assert_equal({}, run_task)
  end

  def test_non_null_boolean_is_reported_if_nil_included
    Temping.create(:users, temporary: false) do
      validates :active, inclusion: { in: [nil, true, false] }

      with_columns do |t|
        t.boolean :active, null: false
      end
    end

    assert_equal({ 'User' => ['active'] }, run_task)
  end

  def test_non_null_boolean_is_not_reported_if_nil_not_included
    Temping.create(:users, temporary: false) do
      validates :active, inclusion: { in: [true, false] }

      with_columns do |t|
        t.boolean :active, null: false
      end
    end

    assert_equal({}, run_task)
  end

  def test_non_null_boolean_is_not_reported_if_nil_excluded
    Temping.create(:users, temporary: false) do
      validates :active, exclusion: { in: [nil] }

      with_columns do |t|
        t.boolean :active, null: false
      end
    end

    assert_equal({}, run_task)
  end

  def test_non_null_boolean_is_reported_if_nil_not_excluded
    Temping.create(:users, temporary: false) do
      validates :active, exclusion: { in: [false] }

      with_columns do |t|
        t.boolean :active, null: false
      end
    end

    assert_equal({ 'User' => ['active'] }, run_task)
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
