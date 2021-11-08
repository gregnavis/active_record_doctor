# frozen_string_literal: true

class ActiveRecordDoctor::Detectors::ShortPrimaryKeyTypeTest < Minitest::Test
  def test_short_integer_primary_key_is_reported
    if mysql?
      create_table(:companies, id: :int)

      assert_problems(<<~OUTPUT)
        change the type of companies.id to bigint
      OUTPUT
    elsif postgresql?
      create_table(:companies, id: :integer)

      assert_problems(<<~OUTPUT)
        change the type of companies.id to bigint
      OUTPUT
    end
  end

  def test_long_integer_primary_key_is_not_reported
    if mysql?
      create_table(:companies, id: :bigint)

      refute_problems
    elsif postgresql?
      create_table(:companies, id: :bigserial)

      refute_problems
    end
  end

  def test_no_primary_key_is_not_reported
    create_table(:companies, id: false) do |t|
      t.string :name, null: false
    end

    refute_problems
  end

  def test_config_ignore_tables
    create_table(:companies, id: :integer)

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :short_primary_key_type,
          ignore_tables: ["companies"]
      end
    CONFIG

    refute_problems
  end

  def test_global_ignore_tables
    create_table(:companies, id: :integer)

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.global :ignore_tables, ["companies"]
      end
    CONFIG

    refute_problems
  end
end
