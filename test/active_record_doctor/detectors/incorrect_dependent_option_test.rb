# frozen_string_literal: true

class ActiveRecordDoctor::Detectors::IncorrectDependentOptionTest < Minitest::Test
  def test_invoking_no_callbacks_suggests_delete_all
    create_table(:companies) do
    end.create_model do
      has_many :users, dependent: :destroy
    end

    create_table(:users) do |t|
      t.references :companies
    end.create_model do
      belongs_to :company
    end

    assert_success(<<OUTPUT)
The following associations might be using invalid dependent settings:
  ModelFactory::Models::Company: users loads models one-by-one to invoke callbacks even though the related model defines none - consider using `dependent: :delete_all`
OUTPUT
  end

  def test_invoking_callbacks_does_not_suggest_delete_all
    create_table(:companies) do
    end.create_model do
      has_many :users, dependent: :destroy
    end

    create_table(:users) do |t|
      t.references :companies
    end.create_model do
      belongs_to :company

      before_destroy :log

      def log
      end
    end

    assert_success("")
  end

  def test_skipping_callbacks_suggests_destroy
    create_table(:companies) do
    end.create_model do
      has_many :users, dependent: :delete_all
    end

    create_table(:users) do |t|
      t.references :companies
    end.create_model do
      belongs_to :company

      before_destroy :log

      def log
      end
    end

    assert_success(<<OUTPUT)
The following associations might be using invalid dependent settings:
  ModelFactory::Models::Company: users skips callbacks that are defined on the associated model - consider changing to `dependent: :destroy` or similar
OUTPUT
  end

  def test_invoking_callbacks_does_not_suggest_destroy
    create_table(:companies) do
    end.create_model do
      has_many :users, dependent: :destroy
    end

    create_table(:users) do |t|
      t.references :companies
    end.create_model do
      belongs_to :company

      before_destroy :log

      def log
      end
    end

    assert_success("")
  end

  def test_works_on_has_one
    create_table(:companies) do
    end.create_model do
      has_one :owner, class_name: "ModelFactory::Models::User", dependent: :destroy
    end

    create_table(:users) do |t|
      t.references :companies
    end.create_model do
      belongs_to :company
    end

    assert_success(<<OUTPUT)
The following associations might be using invalid dependent settings:
  ModelFactory::Models::Company: owner loads models one-by-one to invoke callbacks even though the related model defines none - consider using `dependent: :delete_all`
OUTPUT
  end

  def test_no_dependent_suggests_nothing
    create_table(:companies) do
    end.create_model do
      has_many :users
    end

    create_table(:users) do |t|
      t.references :companies
    end.create_model do
      belongs_to :company
    end

    assert_success("")
  end
end
