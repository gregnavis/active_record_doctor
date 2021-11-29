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
* Bug fix: add_indexes_generator uses the correct migration version.
* Bug fix: add_indexes_generattor truncates long index names (contributed by
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
* Bug fix: incorrect_boolean_presence_validation, missing_non_null_constraint and
  missing_presence_validation skip models whose underlying tables don't exist
  (thanks to rhymes for the fix).
* Bug fix: fix a bug in incorrect_boolean_presence_validation that caused
  exceptions (thanks to Eito Katagiri for the fix).
* Bug fix: add a missing dependency on activesupport (thanks to Yuto Ito for
  the fix).
* Bug fix: make missing_unique_indexes work on custom validators (thanks to Max
  Schwenk for the fix).
* Bug fix: make missing_unique_indexes order-independent so that it no longer
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
* Bug fix: make missing_unique_indexes work in Rails 6 (thanks for Hrvoje Šimić
  for the fix).
* Enhancement: support view-backed models in undefined_table_references.

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
