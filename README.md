# Active Record Doctor

Active Record Doctor helps to keep the database in a good shape. Currently, it
can detect:

* extraneous indexes - [`active_record_doctor:extraneous_indexes`](#removing-extraneous-indexes)
* unindexed `deleted_at` columns - [`active_record_doctor:unindexed_deleted_at`](#detecting-unindexed-deleted_at-columns)
* missing foreign key constraints - [`active_record_doctor:missing_foreign_keys`](#detecting-missing-foreign-key-constraints)
* models referencing undefined tables - [`active_record_doctor:undefined_table_references`](#detecting-models-referencing-undefined-tables)
* uniqueness validations not backed by a unique index - [`active_record_doctor:missing_unique_indexes`](#detecting-uniqueness-validations-not-backed-by-an-index)
* missing non-`NULL` constraints - [`active_record_doctor:missing_non_null_constraint`](#detecting-missing-non-null-constraints)
* missing presence validations - [`active_record_doctor:missing_presence_validation`](#detecting-missing-presence-validations)
* incorrect presence validations on boolean columns - [`active_record_doctor:incorrect_boolean_presence_validation`](#detecting-incorrect-presence-validations-on-boolean-columns)
* mismatches between model length validations and database validation constraints - [`active_record_doctor:incorrect_length_validation`](#detecting-incorrect-length-validation)
* incorrect values of `dependent` on associations - [`active_record_doctor:incorrect_dependent_option`](#detecting-incorrect-dependent-option-on-associations)
* primary keys having short integer types - [`active_record_doctor:short_primary_key_type`](#detecting-primary-keys-having-short-integer-types)
* mismatched foreign key types - [`active_record_doctor:mismatched_foreign_key_type`](#detecting-mismatched-foreign-key-types)
* tables without primary keys - [`active_record_doctor:table_without_primary_key`](#detecting-tables-without-primary-keys)
* tables without timestamps - [`active_record_doctor:table_without_timestamps`](#detecting-tables-without-timestamps)
* incorrect timestamp types on PostgreSQL (timestamps without time zone) - [`active_record_doctor:incorrect_timestamp_type`](#detecting-incorrect-timestamp-types-on-postgresql)

It can also:

* index unindexed foreign keys - [`active_record_doctor:unindexed_foreign_keys`](#indexing-unindexed-foreign-keys)

[![Build Status](https://github.com/gregnavis/active_record_doctor/actions/workflows/lint.yml/badge.svg?branch=master)](https://github.com/gregnavis/active_record_doctor/actions/workflows/lint.yml)
[![Build Status](https://github.com/gregnavis/active_record_doctor/actions/workflows/mysql.yml/badge.svg?branch=master)](https://github.com/gregnavis/active_record_doctor/actions/workflows/mysql.yml)
[![Build Status](https://github.com/gregnavis/active_record_doctor/actions/workflows/postgresql.yml/badge.svg?branch=master)](https://github.com/gregnavis/active_record_doctor/actions/workflows/postgresql.yml)

## Installation

In order to use the latest production release, please add the following to
your `Gemfile`:

```ruby
gem 'active_record_doctor', group: [:development, :test]
```

and run `bundle install`. If you'd like to use the most recent development
version then use this instead:

```ruby
gem 'active_record_doctor', github: 'gregnavis/active_record_doctor', group: [:development, :test]
```

That's it when it comes to Rails projects. If your project doesn't use Rails
then you can use `active_record_doctor` via `Rakefile`.

### Additional Installation Steps for non-Rails Projects

If your project uses Rake then you can add the following to `Rakefile` in order
to use `active_record_doctor`:

```ruby
require "active_record_doctor"

ActiveRecordDoctor::Rake::Task.new do |task|
  # Add project-specific Rake dependencies that should be run before running
  # active_record_doctor.
  task.deps = []

  # A path to your active_record_doctor configuration file.
  task.config_path = ::Rails.root.join(".active_record_doctor.rb")

  # A Proc called right before running detectors that should ensure your Active
  # Record models are preloaded and a database connection is ready.
  task.setup = -> { ::Rails.application.eager_load! }
end
```

**IMPORTANT**. `active_record_doctor` expects that after running `deps` and
calling `setup` your Active Record models are loaded and a database connection
is established.

## Usage

`active_record_doctor` can be used via `rake` or `rails`.

You can run all available detectors via:

```
bundle exec rake active_record_doctor
```

You can run a specific detector via:

```
bundle exec rake active_record_doctor:extraneous_indexes
```

### Continuous Integration

If you want to use `active_record_doctor` in a Continuous Integration setting
then ensure the configuration file is committed and run the tool as one of your
build steps -- it returns a non-zero exit status if any errors were reported.

### Obtaining Help

If you'd like to obtain help on a specific detector then use the `help`
sub-task:

```
bundle exec rake active_record_doctor:extraneous_indexes:help
```

This will show the detector help text in the terminal, along with supported
configuration options, their meaning, and whether they're global or local.

### Debug Logging

It may be that `active_record_doctor` fails with an exception and it is hard to tell
what went wrong. For easier debugging, use `ACTIVE_RECORD_DOCTOR_DEBUG` environment variable.
If `active_record_doctor` fails for some reason for your application, feel free
to open an issue or a PR with the fix.

```
ACTIVE_RECORD_DOCTOR_DEBUG=1 bundle exec rake active_record_doctor
```

### Configuration

`active_record_doctor` can be configured to better suit your project's needs.
For example, if it complains about a model that you want ignored then you can
add that model to the configuration file.

If you want to use the default configuration then you don't have to do anything.
Just run `active_record_doctor` in your project directory.

If you want to customize the tool you should create a file named
`.active_record_doctor.rb` in your project root directory with content like:

```ruby
ActiveRecordDoctor.configure do
  # Global settings affect all detectors.
  global :ignore_tables, [
    # Ignore internal Rails-related tables.
    "ar_internal_metadata",
    "schema_migrations",
    "active_storage_blobs",
    "active_storage_attachments",
    "action_text_rich_texts",

    # Add project-specific tables here.
    "legacy_users"
  ]

  # Detector-specific settings affect only one specific detector.
  detector :extraneous_indexes,
    ignore_tables: ["users"],
    ignore_indexes: ["accounts_on_email_organization_id"]
end
```

The configuration file above will make `active_record_doctor` ignore internal
Rails tables (which are ignored by default) and also the `legacy_users` table.
It'll also make the `extraneous_indexes` detector skip the `users` table
entirely and will not report the index named `accounts_on_email_organization_id`
as extraneous.

Configuration options for each detector are listed below. They can also be
obtained via the help mechanism described in the previous section.

### Regexp-Based Ignores

Settings like `ignore_tables`, `ignore_indexes`, `ignore_models` and so on
accept list of identifiers to ignore. These can be either:

1. Strings - in which case an exact match is needed.
2. Regexps - which are matched against object names, and matching ones are
   excluded from output.

For example, to ignore all tables starting with `legacy_` and all models under
the `Legacy::` namespace you can write:

```ruby
ActiveRecordDoctor.configure do
  global :ignore_tables, [
    # Ignore all legacy tables.
    /^legacy_/
  ]
  global :ignore_models, [
    # Ignore all legacy models.
    /^Legacy::/
  ]
end
```

### Indexing Unindexed Foreign Keys

Foreign keys should be indexed unless it's proven ineffective. However, Rails
makes it easy to create an unindexed foreign key. Active Record Doctor can
automatically generate database migrations that add the missing indexes. It's a
three-step process:

1. Generate a list of unindexed foreign keys by running

  ```bash
  bundle exec rake active_record_doctor:unindexed_foreign_keys > unindexed_foreign_keys.txt
  ```

2. Remove columns that should _not_ be indexed from `unindexed_foreign_keys.txt`
   as a column can look like a foreign key (i.e. ending with `_id`) without being
   one.

3. Generate the migrations

  ```bash
  rails generate active_record_doctor:add_indexes unindexed_foreign_keys.txt
  ```

4. Run the migrations

  ```bash
  bundle exec rake db:migrate
  ```

Supported configuration options:

- `enabled` - set to `false` to disable the detector altogether
- `ignore_tables` - tables whose foreign keys should not be checked
- `ignore_columns` - columns, written as table.column, that should not be
  checked.

### Removing Extraneous Indexes

Let me illustrate with an example. Consider a `users` table with columns
`first_name` and `last_name`. If there are two indexes:

* A two-column index on `last_name, first_name`.
* A single-column index on `last_name`.

Then the latter index can be dropped as the former can play its role. In
general, a multi-column index on `column_1, column_2, ..., column_n` can replace
indexes on:

* `column_1`
* `column_1, column_2`
* ...
* `column_1, column_2, ..., column_(n - 1)`

To discover such indexes automatically just follow these steps:

1. List extraneous indexes by running:

  ```bash
  bundle exec rake active_record_doctor:extraneous_indexes
  ```

2. Confirm that each of the indexes can be indeed dropped.

3. Create a migration to drop the indexes.

The indexes aren't dropped automatically because there are usually just a few of
them and it's a good idea to double-check that you won't drop something
necessary.

Also, extra indexes on primary keys are considered extraneous too and will be
reported.

Note that a unique index can _never be replaced by a non-unique one_. For
example, if there's a unique index on `users.login` and a non-unique index on
`users.login, users.domain` then the tool will _not_ suggest dropping
`users.login` as it could violate the uniqueness assumption. However, a unique
index on `users.login, user.domain` might be replaceable with `users.login` as
the uniqueness of the latter implies the uniqueness of the former (if a given
`login` can appear only once then it can be present in only one `login, domain`
pair).

Supported configuration options:

- `enabled` - set to `false` to disable the detector altogether
- `ignore_tables` - tables whose indexes should never be reported as extraneous.
- `ignore_indexes` - indexes that should never be reported as extraneous.

### Detecting Unindexed `deleted_at` Columns

If you soft-delete some models (e.g. with `paranoia`) then you need to modify
your indexes to include only non-deleted rows. Otherwise they will include
logically non-existent rows. This will make them larger and slower to use. Most
of the time they should only cover columns satisfying `deleted_at IS NULL` (to
cover existing records) or `deleted_at IS NOT NULL` (to cover deleted records).

`active_record_doctor` can automatically detect indexes on tables with a
`deleted_at` column. Just run:

```
bundle exec rake active_record_doctor:unindexed_deleted_at
```

This will print a list of indexes that don't have the `deleted_at IS NULL`
clause. Currently, `active_record_doctor` cannot automatically generate
appropriate migrations. You need to do that manually.

Supported configuration options:

- `enabled` - set to `false` to disable the detector altogether
- `ignore_tables` - tables whose indexes should not be checked.
- `ignore_columns` - specific columns, written as table.column, that should not
  be reported as unindexed.
- `ignore_indexes` - specific indexes that should not be reported as excluding a
  timestamp column.
- `column_names` - deletion timestamp column names.

### Detecting Missing Foreign Key Constraints

If `users.profile_id` references a row in `profiles` then this can be expressed
at the database level with a foreign key constraint. It _forces_
`users.profile_id` to point to an existing row in `profiles`. The problem is
that in many legacy Rails apps, the constraint isn't enforced at the database
level.

`active_record_doctor` can automatically detect foreign keys that could benefit
from a foreign key constraint (a future version will generate a migration that
add the constraint; for now, it's your job). You can obtain the list of foreign
keys with the following command:

```bash
bundle exec rake active_record_doctor:missing_foreign_keys
```

In order to add a foreign key constraint to `users.profile_id` use a migration
like:

```ruby
class AddForeignKeyConstraintToUsersProfileId < ActiveRecord::Migration
  def change
    add_foreign_key :users, :profiles
  end
end
```

Supported configuration options:

- `enabled` - set to `false` to disable the detector altogether
- `ignore_tables` - tables whose columns should not be checked.
- `ignore_columns` - columns, written as table.column, that should not be
  checked.

### Detecting Models Referencing Undefined Tables

Active Record guesses the table name based on the class name. There are a few
cases where the name can be wrong (e.g. you forgot to commit a migration or
changed the table name). Active Record Doctor can help you identify these cases
before they hit production.

**IMPORTANT**. Models backed by views are supported only in:

* Rails 5+ and _any_ database or
* Rails 4.2 with PostgreSQL.

The only thing you need to do is run:

```
bundle exec rake active_record_doctor:undefined_table_references
```

If there a model references an undefined table then you'll see a message like
this:

```
Contract references a non-existent table or view named contract_records
```

On top of that `rake` will exit with a status code of 1. This allows you to use
this check as part of your Continuous Integration pipeline.

Supported configuration options:

- `enabled` - set to `false` to disable the detector altogether
- `ignore_models` - models whose underlying tables should not be checked for
  existence.

### Detecting Uniqueness Validations not Backed by an Index

Model-level uniqueness validations, `has_one` and `has_and_belongs_to_many`
associations should be backed by a database index in order to be robust.
Otherwise you risk inserting duplicate values under a heavy load.

In order to detect such validations run:

```
bundle exec rake active_record_doctor:missing_unique_indexes
```

If there are such indexes then the command will print:

```
add a unique index on users(email) - validating uniqueness in the model without an index can lead to duplicates
```

This means that you should create a unique index on `users.email`.

Supported configuration options:

- `enabled` - set to `false` to disable the detector altogether
- `ignore_models` - models whose uniqueness validators should not be checked.
- `ignore_columns` - specific validators, written as Model(column1, ...), that
  should not be checked.
- `ignore_join_tables` - join tables that should not be checked for existence
  of unique indexes.

### Detecting Missing Non-`NULL` Constraints

If there's an unconditional presence validation on a column then it should be
marked as non-`NULL`-able at the database level or should have a `IS NOT NULL`
constraint.

In order to detect columns whose presence is required but that are marked
`null: true` in the database run the following command:

```
bundle exec rake active_record_doctor:missing_non_null_constraint
```

The output of the command is similar to:

```
add `NOT NULL` to users.name - models validates its presence but it's not non-NULL in the database
```

You can mark the columns mentioned in the output as `null: false` by creating a
migration and calling `change_column_null`.

This validator skips models whose corresponding database tables don't exist.

Supported configuration options:

- `enabled` - set to `false` to disable the detector altogether
- `ignore_tables` - tables whose columns should not be checked.
- `ignore_columns` - columns, written as table.column, that should not be
  checked.

### Detecting Missing Presence Validations

If a column is marked as `null: false` then it's likely it should have the
corresponding presence validator.

In order to detect models lacking these validations run:

```
bundle exec rake active_record_doctor:missing_presence_validation
```

The output of the command looks like this:

```
add a `presence` validator to User.email - it's NOT NULL but lacks a validator
add a `presence` validator to User.name - it's NOT NULL but lacks a validator
```

This means `User` should have a presence validator on `email` and `name`.

This validator skips models whose corresponding database tables don't exist.

Supported configuration options:

- `enabled` - set to `false` to disable the detector altogether
- `ignore_models` - models whose underlying tables' columns should not be checked.
- `ignore_attributes` - specific attributes, written as Model.attribute, that
  should not be checked.
- `ignore_columns_with_default` - set to `true` to ignore columns with default values.

### Detecting Incorrect Presence Validations on Boolean Columns

A boolean column's presence should be validated using inclusion or exclusion
validators instead of the usual presence validator.

In order to detect boolean columns whose presence is validated incorrectly run:

```
bundle exec rake active_record_doctor:incorrect_boolean_presence_validation
```

The output of the command looks like this:

```
replace the `presence` validator on User.active with `inclusion` - `presence` can't be used on booleans
```

This means `active` is validated with `presence: true` instead of
`inclusion: { in: [true, false] }` or `exclusion: { in: [nil] }`.

This validator skips models whose corresponding database tables don't exist.

Supported configuration options:

- `enabled` - set to `false` to disable the detector altogether
- `ignore_models` - models whose validators should not be checked.
- `ignore_columns` - attributes, written as Model.attribute, whose validators
  should not be checked.

### Detecting Incorrect Length Validations

String length can be enforced by both the database and the application. If
there's a database limit then it's a good idea to add a model validation to
ensure user-friendly error messages. Similarly, if there's a model validator
without the corresponding database constraint then it's a good idea to add one
to avoid saving invalid models.

In order to detect columns whose length isn't validated properly run:

```
bundle exec rake active_record_doctor:incorrect_length_validation
```

The output of the command looks like this:

```
set the maximum length in the validator of User.email (currently 32) and the database limit on users.email (currently 64) to the same value
add a length validator on User.address to enforce a maximum length of 64 defined on users.address
```

The first message means the validator on `User.email` is checking for a
different maximum than the database limit on `users.email`. The second message
means there's a database limit on `users.address` without the corresponding
model validation.

Supported configuration options:

- `enabled` - set to `false` to disable the detector altogether
- `ignore_models` - models whose validators should not be checked.
- `ignore_attributes` - attributes, written as Model.attribute, whose validators
  should not be checked.

### Detecting Incorrect `dependent` Option on Associations

Cascading model deletions can be sped up with `dependent: :delete_all` (to
delete all dependent models with one SQL query) but only if the deleted models
have no callbacks as they're skipped.

This can lead to two types of errors:

- Using `delete_all` when dependent models define callbacks - they will NOT be
  invoked.
- Using `destroy` when dependent models define no callbacks - dependent models
  will be loaded one by one with no reason

In order to detect associations affected by the two aforementioned problems run
the following command:

```
bundle exec rake active_record_doctor:incorrect_dependent_option
```

The output of the command looks like this:

```
use `dependent: :delete_all` or similar on Company.users - associated models have no validations and can be deleted in bulk
use `dependent: :destroy` or similar on Post.comments - the associated model has callbacks that are currently skipped
```

Supported configuration options:

- `enabled` - set to `false` to disable the detector altogether
- `ignore_models` - models whose associations should not be checked.
- `ignore_associations` - associations, written as Model.association, that should not
  be checked.

### Detecting Primary Keys Having Short Integer Types

Active Record 5.1 changed the default primary and foreign key type from INTEGER
to BIGINT. The reason is to reduce the risk of running out of IDs on inserts.

In order to detect primary keys using shorter integer types, for example created
before migrating to 5.1, you can run the following command:

```
bundle exec rake active_record_doctor:short_primary_key_type
```

The output of the command looks like this:

```
change the type of companies.id to bigint
```

The above means `companies.id` should be migrated to a wider integer type. An
example migration to accomplish this looks like this:

```ruby
class ChangeCompaniesPrimaryKeyType < ActiveRecord::Migration[5.1]
  def change
    change_column :companies, :id, :bigint
  end
end
```

**IMPORTANT**. Running the above migration on a large table can cause downtime
as all rows need to be rewritten.

Supported configuration options:

- `enabled` - set to `false` to disable the detector altogether
- `ignore_tables` - tables whose primary keys should not be checked.

### Detecting Mismatched Foreign Key Types

Foreign keys should be of the same type as the referenced primary key.
Otherwise, there's a risk of bugs caused by IDs representable by one type but
not the other.

Running the command below will list all foreign keys whose type is different
from the referenced primary key:

```
bundle exec rake active_record_doctor:mismatched_foreign_key_type
```

The output of the command looks like this:

```
companies.user_id references a column of a different type - foreign keys should be of the same type as the referenced column
```

Supported configuration options:

- `enabled` - set to `false` to disable the detector altogether
- `ignore_tables` - tables whose foreign keys should not be checked.
- `ignore_columns` - foreign keys, written as table.column, that should not be
  checked.

### Detecting Tables Without Primary Keys

Tables should have primary keys. Otherwise, it becomes problematic to easily find a specific record,
logical replication in PostgreSQL will be troublesome, because all the rows need to be unique
in the table then etc.

Running the command below will list all tables without primary keys:

```
bundle exec rake active_record_doctor:table_without_primary_key
```

The output of the command looks like this:

```
add a primary key to companies
```

Supported configuration options:

- `enabled` - set to `false` to disable the detector altogether
- `ignore_tables` - tables whose primary key existence should not be checked

### Detecting Tables Without Timestamps

Tables should have timestamp columns (`created_at`/`updated_at`). Otherwise, it becomes problematic
to easily find when the record was created/updated, if the table is active or can be removed,
automatic Rails cache expiration after record updates is not possible.

Running the command below will list all tables without default timestamp columns:

```
bundle exec rake active_record_doctor:table_without_timestamps
```

The output of the command looks like this:

```
add a created_at column to companies
```

Supported configuration options:

- `enabled` - set to `false` to disable the detector altogether
- `ignore_tables` - tables whose timestamp columns existence should not be checked

### Detecting Incorrect Timestamp Types on PostgreSQL

PostgreSQL offers two main timestamp types: `timestamp without time zone` and
`timestamp with time zone` (often aliased as `timestamptz`). It is generally
best practice to use `timestamp with time zone` as it stores timestamps in UTC
and automatically handles conversions to and from the client's time zone.
Rails, by default (even in version 8), uses `timestamp without time zone` for
newly generated `datetime` columns in PostgreSQL for legacy reasons.

This detector checks if any timestamp columns in your PostgreSQL
database are using `timestamp without time zone` instead of the recommended
`timestamp with time zone`.

Running the command below will list all such columns:

```
bundle exec rake active_record_doctor:incorrect_timestamp_type
```

The output of the command looks like this:

```
Incorrect timestamp type: The column `users.created_at` is `timestamp without time zone`.
It's recommended to use `timestamp with time zone` for PostgreSQL.

To make `timestamp with time zone` the default for new columns, add the following to `config/application.rb`:

```ruby
ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.datetime_type = :timestamptz
```

After adding this configuration, run `bin/rails db:migrate` to update your `schema.rb`.
For existing columns, you'll need to create a new migration to change the column type, eg:

```ruby
class ChangeTimestampColumnsToTimestamptz < ActiveRecord::Migration[7.0]
  def change
    change_column :users, :created_at, :timestamptz
  end
end
```

Long term, once all columns have been migrated, or for new projects, you should set the default
timestamp type in your `config/application.rb` to ensure all new timestamp columns use UTC:

```ruby
# config/application.rb
config.time_zone = "Europe/London"
config.active_record.default_timezone = :utc
```

Supported configuration options:

- `enabled` - set to `false` to disable the detector altogether
- `ignore_tables` - tables whose timestamp columns should not be checked.
- `ignore_columns` - specific columns, written as `table_name.column_name`, that should not be checked.

## Ruby and Rails Compatibility Policy

The goal of the policy is to ensure proper functioning in reasonable
combinations of Ruby and Rails versions. Specifically:

1. If a Rails version is officially supported by the Rails Core Team then it's
   supported by `active_record_doctor`.
2. If a Ruby version is compatible with a supported Rails version then it's
   also supported by `active_record_doctor`.
3. Only the most recent teeny Ruby versions and patch Rails versions are supported.

## Testing changes

To test changes to `active_record_doctor` you should have a database instance running with a
database of the right name:

```bash
docker run -p 5432:5432 postgres:9.6.0
PGPASSWORD="postgres" psql -U postgres -h localhost -c "CREATE DATABASE active_record_doctor_primary;" -c "CREATE DATABASE active_record_doctor_secondary;"
```

Then execute the tests with:
```bash
DATABASE_USERNAME=postgres DATABASE_HOST=localhost DATABASE_PORT=5432 bundle exec rake test:postgresql
```

## Author

This gem is developed and maintained by [Greg Navis](http://www.gregnavis.com).
