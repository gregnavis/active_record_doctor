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
