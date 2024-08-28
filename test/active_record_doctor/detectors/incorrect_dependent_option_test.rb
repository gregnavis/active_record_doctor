# frozen_string_literal: true

class ActiveRecordDoctor::Detectors::IncorrectDependentOptionTest < Minitest::Test
  def test_invoking_no_callbacks_suggests_delete_all
    Context.create_table(:companies) do
    end.define_model do
      has_many :users, dependent: :destroy
    end

    Context.create_table(:users) do |t|
      t.references :companies
    end.define_model do
      belongs_to :company
    end

    assert_problems(<<~OUTPUT)
      use `dependent: :delete_all` or similar on Context::Company.users - associated model Context::User has no callbacks and can be deleted in bulk
    OUTPUT
  end

  def test_invoking_callbacks_does_not_suggest_delete_all
    Context.create_table(:companies) do
    end.define_model do
      has_many :users, dependent: :destroy
    end

    Context.create_table(:users) do |t|
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
    Context.create_table(:companies) do
    end.define_model do
      has_many :users, dependent: :delete_all
    end

    Context.create_table(:users) do |t|
      t.references :companies
    end.define_model do
      belongs_to :company

      before_destroy :log

      def log
      end
    end

    assert_problems(<<~OUTPUT)
      use `dependent: :destroy` or similar on Context::Company.users - associated model Context::User has callbacks that are currently skipped
    OUTPUT
  end

  def test_invoking_callbacks_does_not_suggest_destroy
    Context.create_table(:companies) do
    end.define_model do
      has_many :users, dependent: :destroy
    end

    Context.create_table(:users) do |t|
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
    Context.create_table(:companies) do
    end.define_model do
      has_one :owner, class_name: "Context::User", dependent: :destroy
    end

    Context.create_table(:users) do |t|
      t.references :companies
    end.define_model do
      belongs_to :company
    end

    assert_problems(<<~OUTPUT)
      use `dependent: :delete` or similar on Context::Company.owner - associated model Context::User has no callbacks and can be deleted without loading
    OUTPUT
  end

  def test_works_on_belongs_to
    Context.create_table(:companies) do
    end.define_model do
      has_many :users
    end

    Context.create_table(:users) do |t|
      t.references :company
    end.define_model do
      belongs_to :company, dependent: :destroy
    end

    assert_problems(<<~OUTPUT)
      use `dependent: :delete` or similar on Context::User.company - associated model Context::Company has no callbacks and can be deleted without loading
    OUTPUT
  end

  def test_no_foreign_key_on_second_level_association
    Context.create_table(:companies) do
    end.define_model do
      has_many :users
      has_many :projects
    end

    Context.create_table(:users) do |t|
      t.references :company
    end.define_model do
      belongs_to :company, dependent: :destroy
    end

    Context.create_table(:projects) do |t|
      t.references :company
    end.define_model do
      belongs_to :company
    end

    assert_problems(<<~OUTPUT)
      use `dependent: :delete` or similar on Context::User.company - associated model Context::Company has no callbacks and can be deleted without loading
    OUTPUT
  end

  def test_nullify_foreign_key_on_second_level_association
    Context.create_table(:companies) do
    end.define_model do
      has_many :users
      has_many :projects
    end

    Context.create_table(:users) do |t|
      t.references :company
    end.define_model do
      belongs_to :company, dependent: :destroy
    end

    Context.create_table(:projects) do |t|
      t.references :company, foreign_key: { on_delete: :nullify }
    end.define_model do
      belongs_to :company
    end

    assert_problems(<<~OUTPUT)
      use `dependent: :delete` or similar on Context::User.company - associated model Context::Company has no callbacks and can be deleted without loading
    OUTPUT
  end

  def test_cascade_foreign_key_and_callbacks_on_second_level_association
    Context.create_table(:companies) do
    end.define_model do
      has_many :users
      has_many :projects
    end

    Context.create_table(:users) do |t|
      t.references :company
    end.define_model do
      belongs_to :company, dependent: :delete
    end

    Context.create_table(:projects) do |t|
      t.references :company, foreign_key: { on_delete: :cascade }
    end.define_model do
      belongs_to :company

      before_destroy :log

      def log
      end
    end

    assert_problems(<<~OUTPUT)
      use `dependent: :destroy` or similar on Context::User.company - associated model Context::Company has callbacks that are currently skipped
    OUTPUT
  end

  def test_cascade_foreign_key_and_no_callbacks_on_second_level_association
    Context.create_table(:companies) do
    end.define_model do
      has_many :users
      has_many :projects
    end

    Context.create_table(:users) do |t|
      t.references :company
    end.define_model do
      belongs_to :company, dependent: :delete
    end

    Context.create_table(:projects) do |t|
      t.references :company, foreign_key: { on_delete: :cascade }
    end.define_model do
      belongs_to :company
    end

    refute_problems
  end

  def test_no_dependent_suggests_nothing
    Context.create_table(:companies) do
    end.define_model do
      has_many :users
    end

    Context.create_table(:users) do |t|
      t.references :companies
    end.define_model do
      belongs_to :company
    end

    refute_problems
  end

  def test_polymorphic_destroy_reported_when_all_associations_deletable
    Context.create_table(:images) do |t|
      t.bigint :imageable_id, null: false
      t.string :imageable_type, null: true
    end.define_model do
      belongs_to :imageable, polymorphic: true, dependent: :destroy
    end

    Context.create_table(:users) do
    end.define_model do
      has_one :image, as: :imageable
    end

    Context.create_table(:companies) do
    end.define_model do
      has_one :image, as: :imageable
    end

    assert_problems(<<~OUTPUT)
      use `dependent: :delete` or similar on Context::Image.imageable - associated models Context::Company, Context::User have no callbacks and can be deleted without loading
    OUTPUT
  end

  def test_polymorphic_destroy_not_reported_when_some_associations_not_deletable
    Context.create_table(:images) do |t|
      t.bigint :imageable_id, null: false
      t.string :imageable_type, null: true
    end.define_model do
      belongs_to :imageable, polymorphic: true, dependent: :destroy
    end

    Context.create_table(:users) do
    end.define_model do
      has_one :image, as: :imageable

      before_destroy :log

      def log
      end
    end

    Context.create_table(:companies) do
    end.define_model do
      has_one :image, as: :imageable
    end

    refute_problems
  end

  def test_polymorphic_delete_reported_when_some_associations_not_deletable
    Context.create_table(:images) do |t|
      t.bigint :imageable_id, null: false
      t.string :imageable_type, null: true
    end.define_model do
      belongs_to :imageable, polymorphic: true, dependent: :delete
    end

    Context.create_table(:users) do
    end.define_model do
      has_one :image, as: :imageable

      before_destroy :log

      def log
      end
    end

    Context.create_table(:companies) do
    end.define_model do
      has_one :image, as: :imageable
    end

    assert_problems(<<~OUTPUT)
      use `dependent: :destroy` or similar on Context::Image.imageable - associated model Context::User has callbacks that are currently skipped
    OUTPUT
  end

  def test_polymorphic_delete_not_reported_when_all_associations_deletable
    Context.create_table(:images) do |t|
      t.bigint :imageable_id, null: false
      t.string :imageable_type, null: true
    end.define_model do
      belongs_to :imageable, polymorphic: true, dependent: :delete
    end

    Context.create_table(:users) do
    end.define_model do
      has_one :image, as: :imageable
    end

    Context.create_table(:companies) do
    end.define_model do
      has_one :image, as: :imageable
    end

    refute_problems
  end

  def test_works_on_has_through_associations_with_destroy
    Context.create_table(:users) do
    end.define_model do
      has_many :posts
      has_many :comments, through: :posts, dependent: :destroy
    end

    Context.create_table(:posts) do |t|
      t.references :users
    end.define_model do
      belongs_to :user
      has_many :comments
    end

    Context.create_table(:comments) do |t|
      t.references :posts
    end.define_model do
      belongs_to :post
    end

    assert_problems(<<~OUTPUT)
      use `dependent: :delete_all` or similar on Context::User.comments - associated join model Context::Post has no callbacks and can be deleted in bulk
    OUTPUT
  end

  def test_works_on_has_through_associations_with_delete_all
    Context.create_table(:users) do
    end.define_model do
      has_many :posts
      has_many :comments, through: :posts, dependent: :delete_all
    end

    Context.create_table(:posts) do |t|
      t.references :users
    end.define_model do
      belongs_to :user
      has_many :comments

      before_destroy :log

      def log
      end
    end

    Context.create_table(:comments) do |t|
      t.references :posts
    end.define_model do
      belongs_to :post
    end

    assert_problems(<<~OUTPUT)
      use `dependent: :destroy` or similar on Context::User.comments - associated join model Context::Post has callbacks that are currently skipped
    OUTPUT
  end

  def test_has_through_associations_when_join_model_incomplete
    Context.create_table(:users) do
    end.define_model do
      has_many :posts
      has_many :comments, through: :posts
    end

    Context.create_table(:posts) do |t|
      t.references :users
    end.define_model do
      # The join model should define has_many :comments, but intentionally skips
      # it for this test case's purpose.
    end

    Context.create_table(:comments) do |t|
      t.references :posts
    end.define_model do
    end

    assert_problems(<<~OUTPUT)
      ensure Context::User.comments is configured correctly - Context::Post.comments may be undefined
    OUTPUT
  end

  def test_destroy_async_and_foreign_key_exists
    Context.create_table(:companies) do
    end.define_model do
      # We need an ActiveJob job defined to appease the ActiveRecord
      class_attribute :destroy_association_async_job, default: Class.new

      has_many :users, dependent: :destroy_async
    end

    Context.create_table(:users) do |t|
      t.references :company, foreign_key: true
    end.define_model

    assert_problems(<<~OUTPUT)
      don't use `dependent: :destroy_async` on Context::Company.users or remove the foreign key from users.company_id - \
      associated models will be deleted in the same transaction along with Context::Company
    OUTPUT
  end

  def test_destroy_async_and_no_foreign_key
    Context.create_table(:companies) do
    end.define_model do
      # We need an ActiveJob job defined to appease the ActiveRecord
      class_attribute :destroy_association_async_job, default: Class.new

      has_many :users, dependent: :destroy_async
    end

    Context.create_table(:users) do |t|
      t.references :company, foreign_key: false
    end.define_model

    refute_problems
  end

  def test_config_ignore_models
    Context.create_table(:companies) do
    end.define_model do
      has_many :users, dependent: :destroy
    end

    Context.create_table(:users) do |t|
      t.references :companies
    end.define_model do
      belongs_to :company
    end

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :incorrect_dependent_option,
          ignore_models: ["Context::Company"]
      end
    CONFIG

    refute_problems
  end

  def test_global_ignore_models
    Context.create_table(:companies) do
    end.define_model do
      has_many :users, dependent: :destroy
    end

    Context.create_table(:users) do |t|
      t.references :companies
    end.define_model do
      belongs_to :company
    end

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.global :ignore_models, ["Context::Company"]
      end
    CONFIG

    refute_problems
  end

  def test_config_ignore_associations
    Context.create_table(:companies) do
    end.define_model do
      has_many :users, dependent: :destroy
    end

    Context.create_table(:users) do |t|
      t.references :companies
    end.define_model do
      belongs_to :company
    end

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :incorrect_dependent_option,
          ignore_associations: [/users/]
      end
    CONFIG

    refute_problems
  end
end
