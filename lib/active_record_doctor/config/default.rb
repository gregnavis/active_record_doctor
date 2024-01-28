# frozen_string_literal: true

ActiveRecordDoctor.configure do
  global :ignore_tables, [
    "ar_internal_metadata",
    "schema_migrations",
    "active_storage_blobs",
    "active_storage_attachments",
    "action_text_rich_texts"
  ]

  detector :extraneous_indexes,
    enabled: true,
    ignore_tables: [],
    ignore_indexes: []

  detector :incorrect_boolean_presence_validation,
    enabled: true,
    ignore_models: [],
    ignore_attributes: []

  detector :incorrect_length_validation,
    enabled: true,
    ignore_models: [],
    ignore_attributes: []

  detector :incorrect_dependent_option,
    enabled: true,
    ignore_models: [],
    ignore_associations: []

  detector :mismatched_foreign_key_type,
    enabled: true,
    ignore_tables: [],
    ignore_columns: []

  detector :missing_foreign_keys,
    enabled: true,
    ignore_tables: [],
    ignore_columns: []

  detector :missing_non_null_constraint,
    enabled: true,
    ignore_tables: [],
    ignore_columns: []

  detector :missing_presence_validation,
    enabled: true,
    ignore_models: [],
    ignore_attributes: [],
    ignore_columns_with_default: false

  detector :missing_unique_indexes,
    enabled: true,
    ignore_models: [],
    ignore_columns: []

  detector :short_primary_key_type,
    enabled: true,
    ignore_tables: []

  detector :table_without_primary_key,
    enabled: true,
    ignore_tables: []

  detector :undefined_table_references,
    enabled: true,
    ignore_models: []

  detector :unindexed_deleted_at,
    enabled: true,
    ignore_tables: [],
    ignore_columns: [],
    ignore_indexes: [],
    column_names: ["deleted_at", "discarded_at"]

  detector :unindexed_foreign_keys,
    enabled: true,
    ignore_tables: [],
    ignore_columns: []
end
