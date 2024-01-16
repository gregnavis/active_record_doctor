# Unreleased

* Bug fix: avoid false positives on missing case-insensitive uniqueness indexes when using [`citext`](https://www.postgresql.org/docs/current/citext.html) strings for Postgres dbs (contributed by gee-forr)

# Version 1.14.0

* Enhancement: the default configuration file has the .rb suffix to help editors
  automatically recognize the content Ruby (contributed by Jon Dufresne).

# Version 1.13.0

* New feature: regexp-based ignore settings (contributed by fatkodima).
* Bug fix: ignore_columns is correctly handed in missing_unique_indexes (
  contributed by fatkodima).
* Bug fix: primary keys are automatically recognized as indexed and unique by
  unindexed_foreign_keys and missing_unique_indexes (contributed by fatkodima).
* Bug fix: a typo in the description of incorrect_boolean_presence_validation
  is fixed (contributed by Jon Dufresne).

# Version 1.12.0

* New feature: detect extraneous indexes on PostgreSQL materialized views
  (contributed by fatkodima).
* New feature: support for case-insensitive validations in
  `missing_unique_indexes` (contributed by fatkodima).
* New feature: support for has_one in `missing_unique_indexes` (contributed by
  fatkodima).
* New feature: support for async options in `incorrect_dependent_option`
  (contributed by fatkodima).
* Bug fix: make Rake integration work in non-Rails projects (contributed by
  fatkodima).
* Bug fix: ignore inherited validations in `missing_unique_indexes` (contributed
  by fatkodima).
* Bug fix: make `extraneous_indexes` work on expression indexes (contributed
  by fatkodima).
* `short_primary_key` type checks only integer indexes as they are the ones at
  the risk of running out (contributed by fatkodima).
* `unindexed_foreign_keys` looks at actual foreign keys, instead of guessing
  based on column name (contributed by fatkodima).
* Improvements and clarifications to documentation and error messages
  (contributed by Kurtis Rainbolt-Greene, Vincent Glennon, and fatkodima).

# Version 1.11.0

* New feature: support for polymorphic associations in
  `missing_non_null_constraint` (contributed by fatkodima).
* New feature: support for foreign tables in PostgreSQL (contributed by
  fatkodima).
* New feature: debug logging for easier troubleshooting.
* Bug fix: `incorrect_length_validation` used to take the first length validator
  on the model, even if it didn't correspond to the column under consideration.
  This is no longer the case (contributed by Julián Lires).
* Bug fix: inclusion and exclusion validators can contain a proc in in: or
  within: which makes them impossible to analyze by active_record_doctor; such
  validations are now skipped (contributed by fatkodima).
* Fixed to documentation for `incorrect_dependent_option` (contributed by
  Erick Santos).
* Bug fix: `mismatched_foreign_key_type` used to always look at the type of the
  primary key in the other table, even if the foreign key was referencing a
  different column; the right column is now taken into account (contributed by
  Bruno Gerotto).
* Bug fix: `incorrect_dependent_option` didn't work correctly on through:
  associations as it would look at the final model (instead of the join model);
  additionally, if the join model lacked the corresponding has_many association
  it would result in `NoMethodError`.

# Version 1.10.0

* New feature: `incorrect_length_validation` detector can identify text-column
  length mismatches between tables and models (suggested by fatkodima).
* New feature: each detector can be enabled or disabled globally via the
  configuration file.
* Enhancement: `missing_non_null_constraints` and `missing_presence_validation`
  recognized `NOT NULL` check constraints (contributed by fatkodima).
* Enhancement: `missing_unique_index` is aware of `has_one` associations and
  recommends creating an index on the corresponding foreign key (contributed by
  fatkodima).
* Bug fix: `missing_unique_indexes` can be satisfied by creating an index on a
  sublist of scope + column. Previously, it'd not accept such sublists even
  though they're enough to guarantee uniqueness (contributed by fatkodima).
* Bug fix: fix `missing_unique_indexes` crashes on function indexes (contributed
  by fatkodima).
* Bug fix: `short_primary_key_type` no longer complains about UUID primary keys
  (contributed by fatkodima).
* Bug fix: `extraneous_indexes` was made aware of non-standard primary key names
  and partial indexes (contributed by fatkodima).
* Bug fix: `extraneous_indexes` properly recognizes smaller indexes to be enough
  to guarantee uniqueness. Previously, it'd skip some smaller indexes and ask
  for a larger index to be created (contributed by fatkodima).
* Bug fix: `unindexed_deleted_at` correctly works on partial indexes intended to
  cover deleted columns. It no longer asks to create a contradictory condition
  (`IS NULL AND IS NOT NULL`) in those cases (contributed by fatkodima).
* Bug fix: `incorrect_dependent_option` works correctly on polymorphic
  associations.
* Bug fix: recognize the PostGIS adapter as PostgreSQL (contributed by
  fatkodima).
* Bug fix: index generators use `index_name_length` (defined by Active Record)
  to ensure index names aren't too long (contributed by fatkodima).
* Tested against Ruby 3.1 via CI (contributed by Peter Goldstein).
* Documentation fixes (contributed by Alistair McKinnell and Kaleb Lape).

# Version 1.9.0

* New feature: support for project-specific configuration and Continuous
  Integration usage.
* New feature: `mismatched_foreign_key_type` can detect foreign keys using a
  different column type than the column they're referencing (contributed by
  fatkodima).
* New feature: `short_primary_key_type` can detect primary keys that use short
  integer types and pose a risk of running out of IDs (contributed by
  fatkodima).
* Enhancement: `missing_non_null_constraint` can now properly handle both STI
  and non-STI inheritance hierarchies (contributed by Greg Navis and fatkodima).
* Enhancement: `incorrect_dependency_option` now supports `belongs_to`
  associations (contributed by fatkodima).
* Enhancement: more built-in Rails tables are ignored by default.
* Bug fix: make `extraneous_indexes` take index options into account when
  comparing them for equivalence (contributed by fatkodima).
* Bug fix: `add_indexes_generator` uses the correct migration version.
* Bug fix: `add_indexes_generattor` truncates long index names (contributed by
  Dusan Orlovic).
* Bug fix: `missing_unique_indexes` reports tables instead of indexes - it
  didn't make sense to talk about indexes on _models_.

# Version 1.8.0

* New feature: `incorrect_dependency_option` can detect cases sub-optimal or
  dangerous use of `:delete_all` or `:destroy` on associations (thanks to Dusan
  Orlovic for the contribution).
* New feature: `all` runs all tasks and exits with a zero status if there were
  no errors.
* New feature: support for MySQL!
* Bug fix: `add_index` in Rails 6 now correctly adds version numbers to
  migrations (thanks to Tatsuya Hoshino for the fix).
* Removed unnecessary dependencies on `railties` and `activesupport`.

# Version 1.7.2

* All rake tasks added by active_record_doctor have a description so that they
  are now shown by `rake -T`.
* Bug fix: `incorrect_boolean_presence_validation`, missing_non_null_constraint
  and missing_presence_validation skip models whose underlying tables don't
  exist (thanks to rhymes for the fix).
* Bug fix: fix a bug in `incorrect_boolean_presence_validation` that caused
  exceptions (thanks to Eito Katagiri for the fix).
* Bug fix: add a missing dependency on `activesupport` (thanks to Yuto Ito for
  the fix).
* Bug fix: make `missing_unique_indexes` work on custom validators (thanks to
  Max Schwenk for the fix).
* Bug fix: make `missing_unique_indexes` order-independent so that it no longer
  reports false-positives when columns are reordered (thanks to rhymes for the
  fix).

# Version 1.7.1

* Bug fix: fix a bug in missing_non_null_constraint that resulted in false
  positives (thanks to Artem Chubchenko for the fix).

# Version 1.7.0

* New feature: detect incorrect boolean column presence validations (they
  must always use inclusion/exclusion instead of presence validators).
* Bug fix: don't report missing presence validations on boolean columns if
  they're properly validated for inclusion/exclusion.
* Bug fix: don't report missing presence validations if the validation is
  defined on the association instead of the foreign key column.
* Bug fix: report missing non-NULL constraints on foreign keys when the presence
  validation is defined on the association.
* Bug fix: make `missing_unique_indexes` work in Rails 6 (thanks to Hrvoje
  Šimić for the fix).
* Enhancement: support view-backed models in `undefined_table_references`.

# Version 1.6.0

* New feature: detect columns validated for presence but missing a non-NULL
  constraint at the database level.
* New feature: detect columns with a non-NULL constraint at the database level
  without the corresponding presence validation.
* Official support for Rubies 1.9.3+ and Rails 4.2+
* Skipping full-text indexes when detecting extraneous indexes (thanks
  Tom)
* Some improvements and fixes in README.md (thanks Jay)

# Version 1.5.0

* New feature: detect indexes unprepared for working with models supporting
  soft-delete (thanks to Jason Fleetwood-Boldt for suggesting this feature).

# Version 1.4.1

* Bug fix: only look for references to undefined tables on models that have a
  table name defined.

# Version 1.4.0

* New feature: detect models referencing undefined tables.

# Version 1.3.1

* Support for Rails 4.2, 5.0 and 5.1.
* Improve errors reported by add_index on malformed inputs.

# Version 1.3.0

* New feature: detect missing foreign key constraints.

# Version 1.2.1

* Support for Rails 5 (thanks @syndbg)

# Version 1.2.0

* New feature: report extraneous indexes on primary keys.
* Bug fix: properly recognise indexes on polymorphic associations (thanks for
  reporting @kvokka and @michaelachrisco)
* Bug fix: handle non-unique indexes correctly
* Clean up the documentation (thanks @Fryguy)

# Version 1.1.1

* Document how to detect extraneous indexes.
* Support Rubies lacking `Array#to_h`.
* Minor refactorings (thanks @mwsteb)

# Version 1.1.0

* New feature: detect extraneous indexes.
* Update the installation instructions.

# Version 1.0.3

* Bug fix: add `rails` to development dependencies.

# Version 1.0.2

* Bug fix: add `rake` to development dependencies.

# Version 1.0.1

* Bug fix: versions in Gemfile.lock.
* Bug fix: don't generate migrations with identical timestamps.

# Version 1.0.0

* Initial release.
* New feature: Detecting and indexing unindexed foreign keys.
