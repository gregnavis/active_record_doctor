# frozen_string_literal: true

class ActiveRecordDoctor::Detectors::ShortPrimaryKeyTypeTest < Minitest::Test
  def setup
    @connection = ActiveRecord::Base.connection
    @connection.enable_extension("uuid-ossp") if postgresql?
    super
  end

  def teardown
    @connection.disable_extension("uuid-ossp") if postgresql?
    super
  end

  def test_short_integer_primary_key_is_reported
    Context.create_table(:companies, id: :int)

    assert_problems(<<~OUTPUT)
      change the type of companies.id to bigint
    OUTPUT
  end

  def test_non_integer_and_non_uuid_primary_key_is_not_reported
    Context.create_table(:companies, id: :string, primary_key: :uuid)
    refute_problems
  end

  def test_long_integer_primary_key_is_not_reported
    Context.create_table(:companies, id: :bigint)
    refute_problems
  end

  def test_uuid_primary_key_is_not_reported
    skip unless postgresql?

    Context.create_table(:companies, id: :uuid)
    refute_problems
  end

  def test_no_primary_key_is_not_reported
    Context.create_table(:companies, id: false) do |t|
      t.string :name, null: false
    end

    refute_problems
  end

  def test_config_ignore_tables
    Context.create_table(:companies, id: :integer)

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :short_primary_key_type,
          ignore_tables: ["companies"]
      end
    CONFIG

    refute_problems
  end

  def test_global_ignore_tables
    Context.create_table(:companies, id: :integer)

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.global :ignore_tables, ["companies"]
      end
    CONFIG

    refute_problems
  end
end
