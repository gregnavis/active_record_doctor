require 'test_helper'

require 'active_record_doctor/tasks/missing_non_null_constraint'

class ActiveRecordDoctor::Tasks::MissingNonNullConstraintTest < ActiveSupport::TestCase
  def test_presence_true_and_null_true
    Temping.create(:users, temporary: false) do
      validates :name, presence: true

      with_columns do |t|
        t.string :name, null: true
      end
    end

    assert_equal({ 'users' => ['name'] }, run_task)
  end

  def test_presence_true_and_null_false
    Temping.create(:users, temporary: false) do
      validates :name, presence: true

      with_columns do |t|
        t.string :name, null: false
      end
    end

    assert_equal({}, run_task)
  end

  def test_presence_false_and_null_true
    Temping.create(:users, temporary: false) do
      validates :name, presence: false

      with_columns do |t|
        t.string :name, null: true
      end
    end

    assert_equal({}, run_task)
  end

  def test_presence_false_and_null_false
    Temping.create(:users, temporary: false) do
      validates :name, presence: false

      with_columns do |t|
        t.string :name, null: false
      end
    end

    assert_equal({}, run_task)
  end

  def test_presence_true_with_if
    Temping.create(:users, temporary: false) do
      validates :name, presence: true, if: -> { false }

      with_columns do |t|
        t.string :name, null: true
      end
    end

    assert_equal({}, run_task)
  end

  def test_presence_true_with_unless
    Temping.create(:users, temporary: false) do
      validates :name, presence: true, unless: -> { false }

      with_columns do |t|
        t.string :name, null: true
      end
    end

    assert_equal({}, run_task)
  end

  def test_presence_true_with_allow_nil
    Temping.create(:users, temporary: false) do
      validates :name, presence: true, allow_nil: true

      with_columns do |t|
        t.string :name, null: true
      end
    end

    assert_equal({}, run_task)
  end
end
