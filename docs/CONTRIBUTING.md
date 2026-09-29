# Contributing to `active_record_doctor`

## General Rules

1. **Discuss before implementing large features** - before opening a PR with
   large changes like adding a new detector open an issue first to get approval
   and feedback from the maintainer. This is to ensure effective use of your
   time with as little rework as possible.
2. **Fix obvious errors right away** - you can open PRs with fixes for obvious
   defects like logic errors, unhandled exceptions, incorrect documentation, and
   so on.
3. Document user-facing changes in `README.md` and `CHANGELOG.md` (under the
   _Next version_ header); internal changes shouldn't be mentioned there as
   users most likely don't care about them.
4. _Ruby and Rails Compatibility Policy_ in `README.md` for information on which
   versions on Ruby and Rails are supported.

## Test Suite

There are three Rake tasks for running the test suite against various databases:

- `bundle exec rake test:sqlite3`
- `bundle exec rake test:mysql2`
- `bundle exec rake test:postgresql`

Additionally, `bundle exec rake test` runs the test suite against all supported
databases.

A single test file can be run via:

```
DATABASE_ADAPTER=<adapter> ruby -Ilib -Itest -rsetup <path to test file>
```

where `<adapter>` is the database adapter name (`sqlite3`, `mysql2` or `postgresql`).
Minitest flags are supported; for example `-n test_disabled_by_default` will
only run the test method named `test_disabled_by_default`.

## Linting

The code can be linted by Rubocop by running:

```
bundle exec rake rubocop
```

All detected issues can be fixed automatically via `rubocop:autocorrect` (safe
fixes only) or `rake rubocop:autocorrect_all` (safe and unsafe fixes).
