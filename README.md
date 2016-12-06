# Active Record Doctor

Active Record Doctor helps to keep the database in a good shape. Currently, it
can:

* index unindexed foreign keys
* detect extraneous indexes
* detect missing foreign key constraints

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

Note that a unique index can _never be replaced by a non-unique one_. For
example, if there's a unique index on `users.login` and a non-unique index on
`users.login, users.domain` then the tool will _not_ suggest dropping
`users.login` as it could violate the uniqueness assumption.

### Detecting Missing Foreign Key Constraints

If `users.profile_id` references a row in `profiles` then this can be expressed
at the database level with a foreign key constraint. It _forces_
`users.profile_id` to point to an existing row in `profiles`. The problem is
that in many legacy Rails apps the constraint isn't enforced at the database
level.

`active_record_doctor` can automatically detect foreign keys that could benefit
from a foreign key constraint (a future version will generate a migrations that
add the constraint; for now, it's your job). You can obtain the list of foreign
keys with the following command:

```bash
rake active_record_doctor:missing_foreign_keys
```

The output will look like:

```
users profile_id
comments user_id article_id
```

Tables are listed one per line. Each line starts with a table name followed by
column names that should have a foreign key constraint. In the example above,
`users.profile_id`, `comments.user_id`, and `comments.article_id` lack a foreign
key constraint.

In order to add a foreign key constraint to `users.profile_id` use the following
migration:

```ruby
class AddForeignKeyConstraintToUsersProfileId < ActiveRecord::Migration
  def change
    add_foreign_key :users, :profiles
  end
end
```

## Author

This gem is developed and maintained by [Greg Navis](http://www.gregnavis.com).
