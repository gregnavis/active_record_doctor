# Active Record Doctor

Active Record Doctor helps to keep the database in a good shape. Currently, it
can:

* index unindexed foreign keys
* detect extraneous indexes

More features coming soon!

Want to suggest a feature? Just shoot me [an email](mailto:contact@gregnavis.com).

[<img src="https://travis-ci.org/gregnavis/active_record_doctor.svg?branch=master" alt="Build Status" />](https://travis-ci.org/gregnavis/active_record_doctor)

## Installation

The preferred installation method is adding `active_record_doctor` to your
`Gemfile`:

```ruby
gem 'active_record_doctor', group: :development
```

Then run:

```bash
bundle install
```

## Usage

### Indexing Unindexed Foreign Keys

Foreign keys should be indexed unless it's proven ineffective. However, Rails
makes it easy to create an unindexed foreign key. Active Record Doctor can
automatically generate database migrations that add the missing indexes. It's a
three-step process:

1. Generate a list of unindexed foreign keys by running

  ```bash
  rake active_record_doctor:unindexed_foreign_keys > unindexed_foreign_keys.txt
  ```

2. Remove columns that should _not_ be indexed from `unindexed_foreign_keys.txt`
   as a column can look like a foreign key (i.e. end with `_id`) without being
   one.

3. Generate the migrations

  ```bash
  rails generate active_record_doctor:add_indexes unindexed_foreign_keys.txt
  ```

4. Run the migrations

  ```bash
  rake db:migrate
  ```

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
  rake active_record_doctor:extraneous_indexes
  ```

2. Confirm that each of the indexes can be indeed dropped.

3. Create a migration to drop the indexes.

The indexes aren't dropped automatically because there's usually just a few of
them and it's a good idea to double-check that you won't drop something
necessary.

Also, extra indexes on primary keys are considered extraneous too and will be
reported.

## Author

This gem is developed and maintained by [Greg Navis](http://www.gregnavis.com).
