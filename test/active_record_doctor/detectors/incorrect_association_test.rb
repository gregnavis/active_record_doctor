# frozen_string_literal: true

class ActiveRecordDoctor::Detectors::IncorrectAssociationTest < Minitest::Test
  def test_belongs_to_without_associated_model_is_reported
    Context.create_table(:users).define_model do
      belongs_to :company
    end

    assert_problems(<<~OUTPUT)
      association Context::User.company is incorrect - associated 'Company' model does not exist
    OUTPUT
  end

  def test_belongs_to_without_associated_table_is_reported
    Context.define_model(:Company)

    Context.create_table(:users).define_model do
      belongs_to :company
    end

    assert_problems(<<~OUTPUT)
      association Context::User.company is incorrect - associated 'companies' table does not exist
    OUTPUT
  end

  def test_belongs_to_without_foreign_key_column_is_reported
    Context.create_table(:companies).define_model

    Context.create_table(:users).define_model do
      belongs_to :company
    end

    assert_problems(<<~OUTPUT)
      association Context::User.company is incorrect - there is no 'users.company_id' column
    OUTPUT
  end

  def test_belongs_to_with_foreign_key_column_is_not_reported
    Context.create_table(:companies).define_model

    Context.create_table(:users) do |t|
      t.integer :company_id
    end.define_model do
      belongs_to :company
    end

    refute_problems
  end

  def test_belongs_to_without_custom_foreign_key_column_is_reported
    Context.create_table(:companies).define_model

    Context.create_table(:users) do |t|
      t.integer :company_id
    end.define_model do
      belongs_to :company, foreign_key: :custom_company_id
    end

    assert_problems(<<~OUTPUT)
      association Context::User.company is incorrect - there is no 'users.custom_company_id' column
    OUTPUT
  end

  def test_belongs_to_with_custom_foreign_key_column_is_not_reported
    Context.create_table(:companies).define_model

    Context.create_table(:users) do |t|
      t.integer :custom_company_id
    end.define_model do
      belongs_to :company, foreign_key: :custom_company_id
    end

    refute_problems
  end

  def test_belongs_to_associated_model_without_primary_key_column_is_reported
    Context.create_table(:companies).define_model

    Context.create_table(:users, id: false) do |t|
      t.integer :company_id
    end.define_model do
      belongs_to :company
    end

    assert_problems(<<~OUTPUT)
      association Context::User.company is incorrect - there is no 'users.id' column
    OUTPUT
  end

  def test_belongs_to_associated_model_with_primary_key_column_is_not_reported
    Context.create_table(:companies).define_model

    Context.create_table(:users) do |t|
      t.integer :company_id
    end.define_model do
      belongs_to :company
    end

    refute_problems
  end

  def test_belongs_to_associated_model_without_cache_count_column_is_reported
    Context.create_table(:companies).define_model

    Context.create_table(:users) do |t|
      t.integer :company_id
    end.define_model do
      belongs_to :company, counter_cache: true
    end

    assert_problems(<<~OUTPUT)
      association Context::User.company is incorrect - there is no 'companies.users_count' counter cache column
    OUTPUT
  end

  def test_belongs_to_associated_model_with_cache_count_column_is_not_reported
    Context.create_table(:companies) do |t|
      t.integer :users_count
    end.define_model

    Context.create_table(:users) do |t|
      t.integer :company_id
    end.define_model do
      belongs_to :company, counter_cache: true
    end

    refute_problems
  end

  def test_belongs_to_associated_model_without_custom_cache_count_column_is_reported
    Context.create_table(:companies) do |t|
      t.integer :users_count
    end.define_model

    Context.create_table(:users) do |t|
      t.integer :company_id
    end.define_model do
      belongs_to :company, counter_cache: :custom_users_count
    end

    assert_problems(<<~OUTPUT)
      association Context::User.company is incorrect - there is no 'companies.custom_users_count' counter cache column
    OUTPUT
  end

  def test_belongs_to_associated_model_with_custom_cache_count_column_is_not_reported
    Context.create_table(:companies) do |t|
      t.integer :custom_users_count
    end.define_model

    Context.create_table(:users) do |t|
      t.integer :company_id
    end.define_model do
      belongs_to :company, counter_cache: :custom_users_count
    end

    refute_problems
  end

  def test_belongs_to_associated_model_without_updated_at_touch_column_is_reported
    Context.create_table(:companies).define_model

    Context.create_table(:users) do |t|
      t.integer :company_id
    end.define_model do
      belongs_to :company, touch: true
    end

    assert_problems(<<~OUTPUT)
      association Context::User.company is incorrect - there is no 'companies.updated_at' touch column
    OUTPUT
  end

  def test_belongs_to_associated_model_with_updated_at_touch_column_is_not_reported
    Context.create_table(:companies) do |t|
      t.timestamp :updated_at
    end.define_model

    Context.create_table(:users) do |t|
      t.integer :company_id
    end.define_model do
      belongs_to :company, touch: true
    end

    refute_problems
  end

  def test_belongs_to_associated_model_without_custom_touch_column_is_reported
    Context.create_table(:companies).define_model

    Context.create_table(:users) do |t|
      t.integer :company_id
    end.define_model do
      belongs_to :company, touch: :custom_column
    end

    # Active Record touches both columns - updated_at and custom_column.
    assert_problems(<<~OUTPUT)
      association Context::User.company is incorrect - there is no 'companies.updated_at' touch column
      association Context::User.company is incorrect - there is no 'companies.custom_column' touch column
    OUTPUT
  end

  def test_belongs_to_associated_model_with_custom_touch_column_is_not_reported
    Context.create_table(:companies) do |t|
      t.timestamp :updated_at
      t.timestamp :custom_column
    end.define_model

    Context.create_table(:users) do |t|
      t.integer :company_id
    end.define_model do
      belongs_to :company, touch: :custom_column
    end

    refute_problems
  end

  def test_belongs_to_without_inverse_of_association_on_associated_model_is_reported
    Context.create_table(:companies).define_model

    Context.create_table(:users) do |t|
      t.integer :company_id
    end.define_model do
      belongs_to :company, inverse_of: :users
    end

    assert_problems(<<~OUTPUT)
      association Context::User.company is incorrect - there is no 'Company.users' association
    OUTPUT
  end

  def test_belongs_to_with_inverse_of_association_on_associated_model_is_not_reported
    Context.create_table(:companies).define_model do
      has_many :users
    end

    Context.create_table(:users) do |t|
      t.integer :company_id
    end.define_model do
      belongs_to :company, inverse_of: :users
    end

    refute_problems
  end

  def test_polymorphic_belongs_to_without_foreign_type_column_is_reported
    Context.create_table(:comments) do |t|
      t.integer :commentable_id
    end.define_model do
      belongs_to :commentable, polymorphic: true
    end

    assert_problems(<<~OUTPUT)
      association Context::Comment.commentable is incorrect - there is no 'comments.commentable_type' column
    OUTPUT
  end

  def test_polymorphic_belongs_to_with_foreign_type_column_is_not_reported
    Context.create_table(:comments) do |t|
      t.integer :commentable_id
      t.string :commentable_type
    end.define_model do
      belongs_to :commentable, polymorphic: true
    end

    refute_problems
  end

  def test_polymorphic_belongs_to_without_custom_foreign_type_column_is_reported
    Context.create_table(:comments) do |t|
      t.integer :commentable_id
    end.define_model do
      belongs_to :commentable, polymorphic: true, foreign_type: :custom_type
    end

    assert_problems(<<~OUTPUT)
      association Context::Comment.commentable is incorrect - there is no 'comments.custom_type' column
    OUTPUT
  end

  def test_polymorphic_belongs_to_with_custom_foreign_type_column_is_not_reported
    Context.create_table(:comments) do |t|
      t.integer :commentable_id
      t.string :custom_type
    end.define_model do
      belongs_to :commentable, polymorphic: true, foreign_type: :custom_type
    end

    refute_problems
  end

  def test_has_many_without_associated_model_is_reported
    Context.create_table(:companies).define_model do
      has_many :users
    end

    assert_problems(<<~OUTPUT)
      association Context::Company.users is incorrect - associated 'User' model does not exist
    OUTPUT
  end

  def test_has_many_without_associated_table_is_reported
    Context.create_table(:companies).define_model do
      has_many :users
    end

    Context.define_model(:User)

    assert_problems(<<~OUTPUT)
      association Context::Company.users is incorrect - associated 'users' table does not exist
    OUTPUT
  end

  def test_has_many_without_associated_foreign_key_column_is_reported
    Context.create_table(:companies).define_model do
      has_many :users
    end

    Context.create_table(:users).define_model

    assert_problems(<<~OUTPUT)
      association Context::Company.users is incorrect - there is no 'users.company_id' column
    OUTPUT
  end

  def test_has_many_with_associated_foreign_key_column_is_not_reported
    Context.create_table(:companies).define_model do
      has_many :users
    end

    Context.create_table(:users) do |t|
      t.integer :company_id
    end.define_model

    refute_problems
  end

  def test_has_many_without_associated_custom_foreign_key_column_is_reported
    Context.create_table(:companies).define_model do
      has_many :users, foreign_key: :custom_company_id
    end

    Context.create_table(:users).define_model

    assert_problems(<<~OUTPUT)
      association Context::Company.users is incorrect - there is no 'users.custom_company_id' column
    OUTPUT
  end

  def test_has_many_with_associated_custom_foreign_key_column_is_not_reported
    Context.create_table(:companies).define_model do
      has_many :users, foreign_key: :custom_company_id
    end

    Context.create_table(:users) do |t|
      t.integer :custom_company_id
    end.define_model

    refute_problems
  end

  def test_polymorphic_has_many_without_associated_foreign_type_column_is_reported
    Context.create_table(:posts).define_model do
      has_many :comments, as: :commentable
    end

    Context.create_table(:comments) do |t|
      t.integer :commentable_id
    end.define_model

    assert_problems(<<~OUTPUT)
      association Context::Post.comments is incorrect - there is no 'comments.commentable_type' column
    OUTPUT
  end

  def test_polymorphic_has_many_with_associated_foreign_type_column_is_not_reported
    Context.create_table(:posts).define_model do
      has_many :comments, as: :commentable
    end

    Context.create_table(:comments) do |t|
      t.integer :commentable_id
      t.string :commentable_type
    end.define_model

    refute_problems
  end

  def test_polymorphic_has_many_without_associated_custom_foreign_type_column_is_reported
    Context.create_table(:posts).define_model do
      has_many :comments, as: :commentable, foreign_type: :custom_type
    end

    Context.create_table(:comments) do |t|
      t.integer :commentable_id
    end.define_model

    assert_problems(<<~OUTPUT)
      association Context::Post.comments is incorrect - there is no 'comments.custom_type' column
    OUTPUT
  end

  def test_polymorphic_has_many_with_associated_custom_foreign_type_column_is_not_reported
    Context.create_table(:posts).define_model do
      has_many :comments, as: :commentable, foreign_type: :custom_type
    end

    Context.create_table(:comments) do |t|
      t.integer :commentable_id
      t.string :custom_type
    end.define_model

    refute_problems
  end

  def test_has_many_without_associated_primary_key_column_is_reported
    Context.create_table(:companies, id: false) do |t|
      t.string :name
    end.define_model do
      has_many :users
    end

    Context.create_table(:users) do |t|
      t.integer :company_id
    end.define_model

    assert_problems(<<~OUTPUT)
      association Context::Company.users is incorrect - there is no 'companies.id' column
    OUTPUT
  end

  def test_has_many_with_associated_primary_key_column_is_not_reported
    Context.create_table(:companies).define_model do
      has_many :users
    end

    Context.create_table(:users) do |t|
      t.integer :company_id
    end.define_model

    refute_problems
  end

  def test_has_many_without_custom_associated_primary_key_column_is_reported
    Context.create_table(:companies).define_model do
      has_many :users, primary_key: :custom_id
    end

    Context.create_table(:users) do |t|
      t.integer :company_id
    end.define_model

    assert_problems(<<~OUTPUT)
      association Context::Company.users is incorrect - there is no 'companies.custom_id' column
    OUTPUT
  end

  def test_has_many_with_custom_associated_primary_key_column_is_not_reported
    Context.create_table(:companies, primary_key: :custom_id).define_model do
      has_many :users, primary_key: :custom_id
    end

    Context.create_table(:users) do |t|
      t.integer :company_id
    end.define_model

    refute_problems
  end

  def test_has_many_without_counter_cache_column_is_reported
    Context.create_table(:companies) do |t|
      t.integer :users_count
    end.define_model do
      has_many :users, counter_cache: :custom_users_count
    end

    Context.create_table(:users) do |t|
      t.integer :company_id
    end.define_model do
      belongs_to :company, counter_cache: :custom_users_count
    end

    assert_problems(<<~OUTPUT)
      association Context::Company.users is incorrect - there is no 'companies.custom_users_count' counter cache column
      association Context::User.company is incorrect - there is no 'companies.custom_users_count' counter cache column
    OUTPUT
  end

  def test_has_many_with_counter_cache_column_is_not_reported
    Context.create_table(:companies) do |t|
      t.integer :custom_users_count
    end.define_model do
      has_many :users, counter_cache: :custom_users_count
    end

    Context.create_table(:users) do |t|
      t.integer :company_id
    end.define_model do
      belongs_to :company, counter_cache: :custom_users_count
    end

    refute_problems
  end

  def test_has_many_without_inverse_of_association_on_associated_model_is_reported
    Context.create_table(:companies).define_model do
      has_many :users, inverse_of: :company
    end

    Context.create_table(:users) do |t|
      t.integer :company_id
    end.define_model

    assert_problems(<<~OUTPUT)
      association Context::Company.users is incorrect - there is no 'User.company' association
    OUTPUT
  end

  def test_has_many_with_inverse_of_association_on_associated_model_is_not_reported
    Context.create_table(:companies).define_model do
      has_many :users, inverse_of: :company
    end

    Context.create_table(:users) do |t|
      t.integer :company_id
    end.define_model do
      belongs_to :company
    end

    refute_problems
  end

  def test_has_many_through_without_through_association_is_reported
    Context.create_table(:companies).define_model do
      has_many :projects, through: :users
    end

    assert_problems(<<~OUTPUT)
      association Context::Company.projects is incorrect - there is no 'Context::Company.users' association
    OUTPUT
  end

  def test_has_many_through_without_source_association_is_reported
    Context.create_table(:companies).define_model do
      has_many :users
      has_many :projects, through: :users
    end

    Context.create_table(:users) do |t|
      t.integer :company_id
    end.define_model

    assert_problems(<<~OUTPUT)
      association Context::Company.projects is incorrect - there is no 'projects' association on 'Context::User' model
    OUTPUT
  end

  def test_has_many_through_with_through_association_is_not_reported
    Context.create_table(:companies).define_model do
      has_many :users
      has_many :projects, through: :users
    end

    Context.create_table(:users) do |t|
      t.integer :company_id
    end.define_model do
      has_many :projects
    end

    Context.create_table(:projects) do |t|
      t.integer :user_id
    end.define_model

    refute_problems
  end

  def test_has_one_without_associated_model_is_reported
    Context.create_table(:users).define_model do
      has_one :account
    end

    assert_problems(<<~OUTPUT)
      association Context::User.account is incorrect - associated 'Account' model does not exist
    OUTPUT
  end

  def test_has_one_without_associated_table_is_reported
    Context.create_table(:users).define_model do
      has_one :account
    end

    Context.define_model(:Account)

    assert_problems(<<~OUTPUT)
      association Context::User.account is incorrect - associated 'accounts' table does not exist
    OUTPUT
  end

  def test_has_one_without_associated_foreign_key_column_is_reported
    Context.create_table(:users).define_model do
      has_one :account
    end

    Context.create_table(:accounts).define_model

    assert_problems(<<~OUTPUT)
      association Context::User.account is incorrect - there is no 'accounts.user_id' column
    OUTPUT
  end

  def test_has_one_with_associated_foreign_key_column_is_not_reported
    Context.create_table(:users).define_model do
      has_one :account
    end

    Context.create_table(:accounts) do |t|
      t.integer :user_id
    end.define_model

    refute_problems
  end

  def test_has_one_without_associated_custom_foreign_key_column_is_reported
    Context.create_table(:users).define_model do
      has_one :account, foreign_key: :custom_user_id
    end

    Context.create_table(:accounts).define_model

    assert_problems(<<~OUTPUT)
      association Context::User.account is incorrect - there is no 'accounts.custom_user_id' column
    OUTPUT
  end

  def test_has_one_with_associated_custom_foreign_key_column_is_not_reported
    Context.create_table(:users).define_model do
      has_one :account, foreign_key: :custom_user_id
    end

    Context.create_table(:accounts) do |t|
      t.integer :custom_user_id
    end.define_model

    refute_problems
  end

  def test_polymorphic_has_one_without_associated_foreign_type_column_is_reported
    Context.create_table(:posts).define_model do
      has_one :comment, as: :commentable
    end

    Context.create_table(:comments) do |t|
      t.integer :commentable_id
    end.define_model

    assert_problems(<<~OUTPUT)
      association Context::Post.comment is incorrect - there is no 'comments.commentable_type' column
    OUTPUT
  end

  def test_polymorphic_has_one_with_associated_foreign_type_column_is_not_reported
    Context.create_table(:posts).define_model do
      has_one :comment, as: :commentable
    end

    Context.create_table(:comments) do |t|
      t.integer :commentable_id
      t.string :commentable_type
    end.define_model

    refute_problems
  end

  def test_polymorphic_has_one_without_associated_custom_foreign_type_column_is_reported
    Context.create_table(:posts).define_model do
      has_one :comment, as: :commentable, foreign_type: :custom_commentable_type
    end

    Context.create_table(:comments) do |t|
      t.integer :commentable_id
    end.define_model

    assert_problems(<<~OUTPUT)
      association Context::Post.comment is incorrect - there is no 'comments.custom_commentable_type' column
    OUTPUT
  end

  def test_polymorphic_has_one_with_associated_custom_foreign_type_column_is_not_reported
    Context.create_table(:posts).define_model do
      has_one :comment, as: :commentable, foreign_type: :custom_commentable_type
    end

    Context.create_table(:comments) do |t|
      t.integer :commentable_id
      t.string :custom_commentable_type
    end.define_model

    refute_problems
  end

  def test_has_one_without_associated_primary_key_column_is_reported
    Context.create_table(:users, id: false) do |t|
      t.string :name
    end.define_model do
      has_one :account
    end

    Context.create_table(:accounts) do |t|
      t.integer :user_id
    end.define_model

    assert_problems(<<~OUTPUT)
      association Context::User.account is incorrect - there is no 'users.id' column
    OUTPUT
  end

  def test_has_one_with_associated_primary_key_column_is_not_reported
    Context.create_table(:users).define_model do
      has_one :account
    end

    Context.create_table(:accounts) do |t|
      t.integer :user_id
    end.define_model

    refute_problems
  end

  def test_has_one_without_custom_associated_primary_key_column_is_reported
    Context.create_table(:users).define_model do
      has_one :account, primary_key: :custom_id
    end

    Context.create_table(:accounts) do |t|
      t.integer :user_id
    end.define_model

    assert_problems(<<~OUTPUT)
      association Context::User.account is incorrect - there is no 'users.custom_id' column
    OUTPUT
  end

  def test_has_one_with_custom_associated_primary_key_column_is_not_reported
    Context.create_table(:users, primary_key: :custom_id).define_model do
      has_one :account, primary_key: :custom_id
    end

    Context.create_table(:accounts) do |t|
      t.integer :user_id
    end.define_model

    refute_problems
  end

  def test_has_one_without_inverse_of_association_on_associated_model_is_reported
    Context.create_table(:users).define_model do
      has_one :account, inverse_of: :user
    end

    Context.create_table(:accounts) do |t|
      t.integer :user_id
    end.define_model

    assert_problems(<<~OUTPUT)
      association Context::User.account is incorrect - there is no 'Account.user' association
    OUTPUT
  end

  def test_has_one_with_inverse_of_association_on_associated_model_is_not_reported
    Context.create_table(:users).define_model do
      has_one :account, inverse_of: :user
    end

    Context.create_table(:accounts) do |t|
      t.integer :user_id
    end.define_model do
      belongs_to :user
    end

    refute_problems
  end

  def test_has_one_through_without_through_association_is_reported
    Context.create_table(:users).define_model do
      has_one :company, through: :account
    end

    assert_problems(<<~OUTPUT)
      association Context::User.company is incorrect - there is no 'Context::User.account' association
    OUTPUT
  end

  def test_has_one_through_with_through_association_is_not_reported
    Context.create_table(:users).define_model do
      has_one :account
      has_one :company, through: :account
    end

    Context.create_table(:accounts) do |t|
      t.integer :user_id
      t.integer :company_id
    end.define_model do
      belongs_to :company
    end

    Context.create_table(:companies).define_model

    refute_problems
  end

  def test_has_one_through_without_source_association_is_reported
    Context.create_table(:users).define_model do
      has_one :account
      has_one :company, through: :account
    end

    Context.create_table(:accounts) do |t|
      t.integer :user_id
    end.define_model

    assert_problems(<<~OUTPUT)
      association Context::User.company is incorrect - there is no 'company' association on 'Context::Account' model
    OUTPUT
  end

  def test_habtm_without_associated_model_is_reported
    Context.create_table(:projects).define_model do
      has_and_belongs_to_many :users
    end

    assert_problems(<<~OUTPUT)
      association Context::Project.users is incorrect - associated 'User' model does not exist
    OUTPUT
  end

  def test_habtm_without_associated_table_is_reported
    Context.create_table(:projects).define_model do
      has_and_belongs_to_many :users
    end

    Context.create_table(:users).define_model

    assert_problems(<<~OUTPUT)
      association Context::Project.users is incorrect - associated 'projects_users' table does not exist
    OUTPUT
  end

  def test_habtm_without_foreign_key_column_is_reported
    Context.create_table(:projects).define_model do
      has_and_belongs_to_many :users
    end

    Context.create_table(:users).define_model

    Context.create_table(:projects_users) do |t|
      t.integer :user_id
    end

    assert_problems(<<~OUTPUT)
      association Context::Project.users is incorrect - there is no 'projects_users.project_id' column
    OUTPUT
  end

  def test_habtm_without_custom_foreign_key_column_is_reported
    Context.create_table(:projects).define_model do
      has_and_belongs_to_many :users, foreign_key: :custom_project_id
    end

    Context.create_table(:users).define_model

    Context.create_table(:projects_users) do |t|
      t.integer :user_id
    end

    assert_problems(<<~OUTPUT)
      association Context::Project.users is incorrect - there is no 'projects_users.custom_project_id' column
    OUTPUT
  end

  def test_habtm_with_custom_foreign_key_column_is_not_reported
    Context.create_table(:projects).define_model do
      has_and_belongs_to_many :users, foreign_key: :custom_project_id
    end

    Context.create_table(:users).define_model

    Context.create_table(:projects_users) do |t|
      t.integer :custom_project_id
      t.integer :user_id
    end

    refute_problems
  end

  def test_habtm_without_association_foreign_key_column_is_reported
    Context.create_table(:projects).define_model do
      has_and_belongs_to_many :users, association_foreign_key: :custom_user_id
    end

    Context.create_table(:users).define_model

    Context.create_table(:projects_users) do |t|
      t.integer :project_id
    end

    assert_problems(<<~OUTPUT)
      association Context::Project.users is incorrect - there is no 'projects_users.custom_user_id' column
    OUTPUT
  end

  def test_habtm_with_association_foreign_key_column_is_not_reported
    Context.create_table(:projects).define_model do
      has_and_belongs_to_many :users, association_foreign_key: :custom_user_id
    end

    Context.create_table(:users).define_model

    Context.create_table(:projects_users) do |t|
      t.integer :project_id
      t.integer :custom_user_id
    end

    refute_problems
  end

  def test_config_ignore_models
    Context.create_table(:users).define_model do
      belongs_to :company
    end

    config_file(<<~CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :incorrect_association,
          ignore_models: ["Context::User"]
      end
    CONFIG

    refute_problems
  end

  def test_global_ignore_models
    Context.create_table(:users).define_model do
      belongs_to :company
    end

    config_file(<<~CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.global :ignore_models, ["Context::User"]
      end
    CONFIG

    refute_problems
  end

  def test_config_ignore_associations
    Context.create_table(:users).define_model do
      belongs_to :company
    end

    config_file(<<~CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :incorrect_association,
          ignore_associations: ["Context::User.company"]
      end
    CONFIG

    refute_problems
  end
end
