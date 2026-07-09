# frozen_string_literal: true

class ActiveRecordDoctor::Detectors::MismatchedSequenceTypeTest < Minitest::Test
  def test_non_postgresql_generates_no_errors
    skip if postgresql?

    Context.create_table(:companies, id: :integer)
    refute_problems
  end

  def test_matching_integer_primary_key_and_sequence_is_not_reported
    skip unless postgresql?

    Context.create_table(:companies, id: :integer)
    refute_problems
  end

  def test_matching_bigint_primary_key_and_sequence_is_not_reported
    skip unless postgresql?

    Context.create_table(:companies, id: :bigint)
    refute_problems
  end

  def test_bigint_column_with_integer_sequence_is_reported
    skip unless postgresql?

    Context.create_table(:companies, id: :integer)
    # Widen the column without changing the sequence so the types diverge.
    @connection.execute("ALTER TABLE companies ALTER COLUMN id TYPE bigint")

    sequence = fetch_sequence("companies", "id")
    assert sequence, "Expected a sequence to exist for companies.id"

    assert_problems(<<~OUTPUT)
      the sequence #{sequence} has type integer but companies.id is bigint - change the sequence type to bigint
    OUTPUT
  end

  def test_bigint_column_with_smallint_sequence_is_reported
    skip unless postgresql?

    # Create with integer (gets a sequence), downgrade sequence to smallint,
    # then widen the column to bigint — leaving a too-small sequence behind.
    Context.create_table(:companies, id: :integer)
    sequence = fetch_sequence("companies", "id")
    assert sequence, "Expected a sequence to exist for companies.id"
    @connection.execute("ALTER SEQUENCE #{sequence} AS smallint MAXVALUE 32767 RESTART 1")
    @connection.execute("ALTER TABLE companies ALTER COLUMN id TYPE bigint")

    assert_problems(<<~OUTPUT)
      the sequence #{sequence} has type smallint but companies.id is bigint - change the sequence type to bigint
    OUTPUT
  end

  def test_integer_column_with_smallint_sequence_is_reported
    skip unless postgresql?

    # Create with integer (gets a sequence), then downgrade the sequence type
    # to smallint — the column remains integer but the sequence is now too small.
    Context.create_table(:companies, id: :integer)
    sequence = fetch_sequence("companies", "id")
    assert sequence, "Expected a sequence to exist for companies.id"
    @connection.execute("ALTER SEQUENCE #{sequence} AS smallint MAXVALUE 32767 RESTART 1")

    assert_problems(<<~OUTPUT)
      the sequence #{sequence} has type smallint but companies.id is integer - change the sequence type to integer
    OUTPUT
  end

  def test_uuid_primary_key_is_not_reported
    skip unless postgresql?

    require_uuid_column_type!

    Context.create_table(:companies, id: :uuid)
    refute_problems
  end

  def test_no_primary_key_is_not_reported
    skip unless postgresql?

    Context.create_table(:companies, id: false) do |t|
      t.string :name, null: false
    end

    refute_problems
  end

  def test_config_ignore_tables
    skip unless postgresql?

    Context.create_table(:companies, id: :integer)
    @connection.execute("ALTER TABLE companies ALTER COLUMN id TYPE bigint")

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :mismatched_sequence_type,
          ignore_tables: ["companies"]
      end
    CONFIG

    refute_problems
  end

  def test_global_ignore_tables
    skip unless postgresql?

    Context.create_table(:companies, id: :integer)
    @connection.execute("ALTER TABLE companies ALTER COLUMN id TYPE bigint")

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.global :ignore_tables, ["companies"]
      end
    CONFIG

    refute_problems
  end

  private

  def setup
    @connection = ActiveRecord::Base.connection
    super
  end

  def fetch_sequence(table, column)
    @connection.select_value(<<~SQL)
      SELECT n.nspname || '.' || seq.relname
      FROM pg_class seq
      JOIN pg_namespace n ON n.oid = seq.relnamespace
      JOIN pg_depend dep
        ON dep.objid = seq.oid
       AND dep.classid = 'pg_class'::regclass
       AND dep.refobjid = #{@connection.quote(table)}::regclass
       AND dep.refobjsubid = (
             SELECT attnum FROM pg_attribute
             WHERE attrelid = #{@connection.quote(table)}::regclass
               AND attname = #{@connection.quote(column)}
           )
       AND dep.deptype IN ('a', 'i')
      WHERE seq.relkind = 'S'
      LIMIT 1
    SQL
  end
end
