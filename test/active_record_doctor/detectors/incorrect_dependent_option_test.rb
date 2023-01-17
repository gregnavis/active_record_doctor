# frozen_string_literal: true

class ActiveRecordDoctor::Detectors::IncorrectDependentOptionTest < Minitest::Test
  def test_invoking_no_callbacks_suggests_delete_all
    create_table(:companies) do
    end.define_model do
      has_many :users, dependent: :destroy
    end

    create_table(:users) do |t|
      t.references :companies
    end.define_model do
      belongs_to :company
    end

    assert_problems(<<~OUTPUT)
      use `dependent: :delete_all` or similar on TransientRecord::Models::Company.users - associated model TransientRecord::Models::User has no validations and can be deleted in bulk
    OUTPUT
  end

  def test_invoking_callbacks_does_not_suggest_delete_all
    create_table(:companies) do
    end.define_model do
      has_many :users, dependent: :destroy
    end

    create_table(:users) do |t|
      t.references :companies
    end.define_model do
      belongs_to :company

      before_destroy :log

      def log
      end
    end

    refute_problems
  end

  def test_skipping_callbacks_suggests_destroy
    create_table(:companies) do
    end.define_model do
      has_many :users, dependent: :delete_all
    end

    create_table(:users) do |t|
      t.references :companies
    end.define_model do
      belongs_to :company

      before_destroy :log

      def log
      end
    end

    assert_problems(<<~OUTPUT)
      use `dependent: :destroy` or similar on TransientRecord::Models::Company.users - the associated model TransientRecord::Models::User has callbacks that are currently skipped
    OUTPUT
  end

  def test_invoking_callbacks_does_not_suggest_destroy
    create_table(:companies) do
    end.define_model do
      has_many :users, dependent: :destroy
    end

    create_table(:users) do |t|
      t.references :companies
    end.define_model do
      belongs_to :company

      before_destroy :log

      def log
      end
    end

    refute_problems
  end

  def test_works_on_has_one
    create_table(:companies) do
    end.define_model do
      has_one :owner, class_name: "TransientRecord::Models::User", dependent: :destroy
    end

    create_table(:users) do |t|
      t.references :companies
    end.define_model do
      belongs_to :company
    end

    assert_problems(<<~OUTPUT)
      use `dependent: :delete` or similar on TransientRecord::Models::Company.owner - the associated model TransientRecord::Models::User has no callbacks and can be deleted without loading
    OUTPUT
  end

  def test_works_on_belongs_to
    create_table(:companies) do
    end.define_model do
      has_many :users
    end

    create_table(:users) do |t|
      t.references :company
    end.define_model do
      belongs_to :company, dependent: :destroy
    end

    assert_problems(<<~OUTPUT)
      use `dependent: :delete` or similar on TransientRecord::Models::User.company - the associated model TransientRecord::Models::Company has no callbacks and can be deleted without loading
    OUTPUT
  end

  def test_no_foreign_key_on_second_level_association
    create_table(:companies) do
    end.define_model do
      has_many :users
      has_many :projects
    end

    create_table(:users) do |t|
      t.references :company
    end.define_model do
      belongs_to :company, dependent: :destroy
    end

    create_table(:projects) do |t|
      t.references :company
    end.define_model do
      belongs_to :company
    end

    assert_problems(<<~OUTPUT)
      use `dependent: :delete` or similar on TransientRecord::Models::User.company - the associated model TransientRecord::Models::Company has no callbacks and can be deleted without loading
    OUTPUT
  end

  def test_nullify_foreign_key_on_second_level_association
    create_table(:companies) do
    end.define_model do
      has_many :users
      has_many :projects
    end

    create_table(:users) do |t|
      t.references :company
    end.define_model do
      belongs_to :company, dependent: :destroy
    end

    create_table(:projects) do |t|
      t.references :company, foreign_key: { on_delete: :nullify }
    end.define_model do
      belongs_to :company
    end

    assert_problems(<<~OUTPUT)
      use `dependent: :delete` or similar on TransientRecord::Models::User.company - the associated model TransientRecord::Models::Company has no callbacks and can be deleted without loading
    OUTPUT
  end

  def test_cascade_foreign_key_and_callbacks_on_second_level_association
    create_table(:companies) do
    end.define_model do
      has_many :users
      has_many :projects
    end

    create_table(:users) do |t|
      t.references :company
    end.define_model do
      belongs_to :company, dependent: :delete
    end

    create_table(:projects) do |t|
      t.references :company, foreign_key: { on_delete: :cascade }
    end.define_model do
      belongs_to :company

      before_destroy :log

      def log
      end
    end

    assert_problems(<<~OUTPUT)
      use `dependent: :destroy` or similar on TransientRecord::Models::User.company - the associated model TransientRecord::Models::Company has callbacks that are currently skipped
    OUTPUT
  end

  def test_cascade_foreign_key_and_no_callbacks_on_second_level_association
    create_table(:companies) do
    end.define_model do
      has_many :users
      has_many :projects
    end

    create_table(:users) do |t|
      t.references :company
    end.define_model do
      belongs_to :company, dependent: :delete
    end

    create_table(:projects) do |t|
      t.references :company, foreign_key: { on_delete: :cascade }
    end.define_model do
      belongs_to :company
    end

    refute_problems
  end

  def test_no_dependent_suggests_nothing
    create_table(:companies) do
    end.define_model do
      has_many :users
    end

    create_table(:users) do |t|
      t.references :companies
    end.define_model do
      belongs_to :company
    end

    refute_problems
  end

  def test_polymorphic_destroy_reported_when_all_associations_deletable
    create_table(:images) do |t|
      t.bigint :imageable_id, null: false
      t.string :imageable_type, null: true
    end.define_model do
      belongs_to :imageable, polymorphic: true, dependent: :destroy
    end

    create_table(:users) do
    end.define_model do
      has_one :image, as: :imageable
    end

    create_table(:companies) do
    end.define_model do
      has_one :image, as: :imageable
    end

    assert_problems(<<~OUTPUT)
      use `dependent: :delete` or similar on TransientRecord::Models::Image.imageable - the associated models TransientRecord::Models::Company, TransientRecord::Models::User have no callbacks and can be deleted without loading
    OUTPUT
  end

  def test_polymorphic_destroy_not_reported_when_some_associations_not_deletable
    create_table(:images) do |t|
      t.bigint :imageable_id, null: false
      t.string :imageable_type, null: true
    end.define_model do
      belongs_to :imageable, polymorphic: true, dependent: :destroy
    end

    create_table(:users) do
    end.define_model do
      has_one :image, as: :imageable

      before_destroy :log

      def log
      end
    end

    create_table(:companies) do
    end.define_model do
      has_one :image, as: :imageable
    end

    refute_problems
  end

  def test_polymorphic_delete_reported_when_some_associations_not_deletable
    create_table(:images) do |t|
      t.bigint :imageable_id, null: false
      t.string :imageable_type, null: true
    end.define_model do
      belongs_to :imageable, polymorphic: true, dependent: :delete
    end

    create_table(:users) do
    end.define_model do
      has_one :image, as: :imageable

      before_destroy :log

      def log
      end
    end

    create_table(:companies) do
    end.define_model do
      has_one :image, as: :imageable
    end

    assert_problems(<<~OUTPUT)
      use `dependent: :destroy` or similar on TransientRecord::Models::Image.imageable - the associated model TransientRecord::Models::User has callbacks that are currently skipped
    OUTPUT
  end

  def test_polymorphic_delete_not_reported_when_all_associations_deletable
    create_table(:images) do |t|
      t.bigint :imageable_id, null: false
      t.string :imageable_type, null: true
    end.define_model do
      belongs_to :imageable, polymorphic: true, dependent: :delete
    end

    create_table(:users) do
    end.define_model do
      has_one :image, as: :imageable
    end

    create_table(:companies) do
    end.define_model do
      has_one :image, as: :imageable
    end

    refute_problems
  end

  def test_config_ignore_models
    create_table(:companies) do
    end.define_model do
      has_many :users, dependent: :destroy
    end

    create_table(:users) do |t|
      t.references :companies
    end.define_model do
      belongs_to :company
    end

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :incorrect_dependent_option,
          ignore_models: ["TransientRecord::Models::Company"]
      end
    CONFIG

    refute_problems
  end

  def test_global_ignore_models
    create_table(:companies) do
    end.define_model do
      has_many :users, dependent: :destroy
    end

    create_table(:users) do |t|
      t.references :companies
    end.define_model do
      belongs_to :company
    end

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.global :ignore_models, ["TransientRecord::Models::Company"]
      end
    CONFIG

    refute_problems
  end

  def test_config_ignore_associations
    create_table(:companies) do
    end.define_model do
      has_many :users, dependent: :destroy
    end

    create_table(:users) do |t|
      t.references :companies
    end.define_model do
      belongs_to :company
    end

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :incorrect_dependent_option,
          ignore_associations: ["TransientRecord::Models::Company.users"]
      end
    CONFIG

    refute_problems
  end
end
