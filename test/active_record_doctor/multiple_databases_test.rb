# frozen_string_literal: true

class ActiveRecordDoctor::MultipleDatabasesTest < Minitest::Test
  SecondaryContext = TransientRecord.context_for SecondaryRecord

  def test_problems_in_secondary_database_are_reported
    SecondaryContext.create_table(:widgets) do |t|
      t.string :name, null: true
    end.define_model do
      validates :name, presence: true
    end

    success, output = run_named_detector(:missing_non_null_constraint)

    refute(success)
    assert_equal(<<~OUTPUT, output)
      add `NOT NULL` to widgets.name - models validates its presence but it's not non-NULL in the database
    OUTPUT
  end

  def test_each_database_is_checked_against_its_own_models
    Context.create_table(:users) do |t|
      t.string :name, null: false
    end.define_model do
      validates :name, presence: true
    end
    SecondaryContext.create_table(:users) do |t|
      t.string :name, null: true
    end.define_model do
      validates :name, presence: true
    end
    SecondaryContext.create_table(:widgets) do |t|
      t.string :name, null: true
    end.define_model

    success, output = run_named_detector(:missing_non_null_constraint)

    refute(success)
    assert_equal(<<~OUTPUT, output)
      add `NOT NULL` to users.name - models validates its presence but it's not non-NULL in the database
    OUTPUT
  end

  def test_table_based_detectors_check_every_database
    Context.create_table(:users)
    SecondaryContext.create_table(:widgets, id: false) do |t|
      t.string :name
    end.define_model

    success, output = run_named_detector(:table_without_primary_key)

    refute(success)
    assert_equal(<<~OUTPUT, output)
      add a primary key to widgets
    OUTPUT
  end

  def test_tables_used_by_models_of_other_databases_are_unused
    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :unused_tables, enabled: true
      end
    CONFIG

    Context.create_table(:widgets)
    SecondaryContext.create_table(:widgets).define_model

    success, output = run_named_detector(:unused_tables)

    refute(success)
    assert_equal(<<~OUTPUT, output)
      The widgets table is not referenced by any Rails model and can be dropped
    OUTPUT
  end

  def test_missing_foreign_keys_skips_associations_across_databases
    Context.create_table(:users)
    Context.define_model(:User)
    SecondaryContext.create_table(:widgets) do |t|
      t.bigint :user_id, null: false
    end.define_model do
      belongs_to :user, class_name: "Context::User"
    end

    success, output = run_named_detector(:missing_foreign_keys)

    assert(success, output)
  end

  def test_abstract_classes_connecting_to_the_same_database_are_checked_once
    skip("each SQLite :memory: connection is a separate database") if sqlite?

    Context.define_model(:OtherRecord) do
      self.abstract_class = true

      connects_to database: { writing: :primary }
    end
    Context.create_table(:users, id: false) do |t|
      t.string :name
    end
    Context.define_model(:User, Context::OtherRecord)

    success, output = run_named_detector(:table_without_primary_key)

    refute(success)
    assert_equal(<<~OUTPUT, output)
      add a primary key to users
    OUTPUT
  end

  def test_associations_to_missing_models_are_checked_as_before
    SecondaryContext.create_table(:widgets) do |t|
      t.bigint :owner_id
    end.define_model do
      belongs_to :owner, class_name: "Nonexistent"
    end

    success, output = run_named_detector(:missing_foreign_keys)

    refute(success)
    assert_equal(<<~OUTPUT, output)
      create a foreign key on widgets.owner_id - looks like an association without a foreign key constraint
    OUTPUT
  end

  def test_errors_resolving_associated_models_other_than_missing_models_are_raised
    Context.create_table(:users).define_model
    Context.create_table(:widgets) do |t|
      t.bigint :user_id
    end.define_model do
      belongs_to :user, class_name: "Context::User"
    end
    Context::Widget.reflect_on_association(:user).define_singleton_method(:klass) do
      raise NoMethodError.new("undefined method")
    end

    assert_raises(NoMethodError) do
      run_named_detector(:missing_foreign_keys)
    end
  end

  def test_dependent_option_is_checked_across_databases
    Context.create_table(:companies).define_model do
      has_many :users, class_name: "#{SecondaryContext.name}::User", dependent: :delete_all
    end
    SecondaryContext.create_table(:users) do |t|
      t.bigint :company_id
    end.define_model do
      before_destroy :log

      def log
      end
    end

    success, output = run_named_detector(:incorrect_dependent_option)

    refute(success)
    assert_equal(<<~OUTPUT, output)
      use `dependent: :destroy` or similar on Context::Company.users - associated model #{SecondaryContext.name}::User has callbacks that are currently skipped
    OUTPUT
  end

  def test_dependent_option_reads_foreign_keys_from_the_associated_database
    Context.create_table(:companies).define_model do
      has_many :users, class_name: "#{SecondaryContext.name}::User", dependent: :destroy
    end
    SecondaryContext.create_table(:users) do |t|
      t.bigint :company_id
    end.define_model do
      has_many :projects, class_name: "#{SecondaryContext.name}::Project"
    end
    SecondaryContext.create_table(:projects) do |t|
      t.references :user, foreign_key: true
    end.define_model

    success, output = run_named_detector(:incorrect_dependent_option)

    assert(success, output)
  end

  def test_has_one_across_databases_without_unique_index
    Context.create_table(:users).define_model do
      has_one :account, class_name: "#{SecondaryContext.name}::Account"
    end
    SecondaryContext.create_table(:accounts) do |t|
      t.bigint :user_id
    end.define_model

    success, output = run_named_detector(:missing_unique_indexes)

    refute(success)
    assert_equal(<<~OUTPUT, output)
      add a unique index on accounts(user_id) - using `has_one` in Context::User without an index can lead to duplicates
    OUTPUT
  end

  def test_has_one_across_databases_with_unique_index
    Context.create_table(:users).define_model do
      has_one :account, class_name: "#{SecondaryContext.name}::Account"
    end
    SecondaryContext.create_table(:accounts) do |t|
      t.bigint :user_id, index: { unique: true }
    end.define_model

    success, output = run_named_detector(:missing_unique_indexes)

    assert(success, output)
  end

  def test_join_tables_with_the_same_name_are_checked_in_each_database
    [Context, SecondaryContext].each do |context|
      context.create_table(:projects).define_model
      context.create_table(:projects_users) do |t|
        t.bigint :user_id
        t.bigint :project_id
      end
      context.create_table(:users).define_model do
        has_and_belongs_to_many :projects, class_name: "#{context.name}::Project"
      end
    end

    success, output = run_named_detector(:missing_unique_indexes)

    refute(success)
    assert_equal(<<~OUTPUT, output)
      add a unique index on projects_users(user_id, project_id) - using `has_and_belongs_to_many` in #{SecondaryContext.name}::User without an index can lead to duplicates
      add a unique index on projects_users(user_id, project_id) - using `has_and_belongs_to_many` in Context::User without an index can lead to duplicates
    OUTPUT
  end

  def test_default_datetime_type_is_reported_once
    skip("#{current_adapter} doesn't have a default datetime type setting") if !postgresql?

    ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.datetime_type = :timestamp
    Context.create_table(:users).define_model
    SecondaryContext.create_table(:widgets).define_model

    success, output = run_named_detector(:postgres_timestamps_without_time_zone)

    refute(success)
    assert_equal(<<~OUTPUT, output)
      PostgreSQL default datetime type should be set to :timestamptz, not :timestamp
    OUTPUT
  ensure
    ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.datetime_type = :timestamptz if postgresql?
  end

  def test_anonymous_models_are_ignored
    anonymous_model = Class.new(ApplicationRecord)
    assert_nil(anonymous_model.name)
    Context.create_table(:users, id: false) do |t|
      t.string :name
    end.define_model

    success, output = run_named_detector(:table_without_primary_key)

    refute(success)
    assert_equal(<<~OUTPUT, output)
      add a primary key to users
    OUTPUT
  end

  def test_models_without_a_connection_pool_are_reported
    Context.define_model(:Orphan) do
      def self.connection_pool
        raise ActiveRecord::ConnectionNotEstablished.new("No connection pool for Orphan")
      end
    end
    Context.create_table(:users).define_model

    success = nil
    output = nil
    assert_output(/Context::Orphan.*No connection pool for Orphan/) do
      success, output = run_named_detector(:table_without_primary_key)
    end

    assert(success, output)
  end

  private

  def run_named_detector(name)
    io = StringIO.new
    runner = ActiveRecordDoctor::Runner.new(
      config: load_config,
      logger: ActiveRecordDoctor::Logger::Dummy.new,
      io: io
    )
    success = runner.run_one(name)
    [success, io.string]
  end
end
