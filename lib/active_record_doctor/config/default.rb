# frozen_string_literal: true

ActiveRecordDoctor.configure do
  global :ignore_tables, [
    "ar_internal_metadata",
    "schema_migrations"
  ]

  detector :extraneous_indexes,
    ignore_tables: [],
    ignore_indexes: []

  detector :incorrect_boolean_presence_validation,
    ignore_models: [],
    ignore_attributes: []

  detector :incorrect_dependent_option,
    ignore_models: [],
    ignore_associations: []

  detector :mismatched_foreign_key_type,
    ignore_tables: [],
    ignore_columns: []

  detector :missing_foreign_keys,
    ignore_tables: [],
    ignore_columns: []

  detector :missing_non_null_constraint,
    ignore_models: [],
    ignore_attributes: []

  detector :missing_presence_validation,
    ignore_models: [],
    ignore_attributes: []

  detector :missing_unique_indexes,
    ignore_models: [],
    ignore_columns: []

  detector :short_primary_key_type,
    ignore_tables: []

  detector :undefined_table_references,
    ignore_models: []

  detector :unindexed_deleted_at,
    ignore_tables: [],
    ignore_columns: [],
    ignore_indexes: [],
    column_names: ["deleted_at", "discarded_at"]

  detector :unindexed_foreign_keys,
    ignore_tables: [],
    ignore_columns: []
end
