# `active_record_doctor` Architecture

`active_record_doctor` can be considered a database and model layer linter - it
uses runtime reflection to identify and signal potentially problematic database
and model issues.

The central idea is that of a **detector** - a Ruby class specialized in
identifying and reporting issues of a specific kind. For example,
`UndefinedTableReferences` is a detector for identifying Active Record models
that reference non-existent tables.

Detectors must meet the following criteria:

1. Inherit from `ActiveRecordDoctor::Detectors::Base`.
2. Be placed under `ActiveRecordDoctor::Detectors`.
3. Define a class instance variable `@description` set to the user-facing
   description of what the detector does.
4. Define a class instance variable `@config` describing the supported
   configuration options (more on that below.)
5. Define a private method named `detect`, the entry point to the detector, that
   will attempt to detect errors the detector should detect and report them by
   calling `#problem!`. `detect` may run once per database, so it should use
   `connection` and `models` instead of `ActiveRecord::Base.connection`, and
   initialize per-run state inside `detect`.
6. Define a private method named `message` that will be called for each
   invocation of `problem!` (with the same arguments) and that should return the
   user-facing description of the detected problem.
7. Detectors should rely on helper methods defined in `Base`, e.g. `each_*` for
   iterating over various entities or `config` for reading configuration
   settings.

## Detector Configuration Options

The class instance variable `@config` is a hash whose keys are names of
configuration options (e.g. `:ignore_models`) and values are definitions of
these options.

There are two types of settings: local and global. Global settings are shared by
all detectors. Local settings are specific to one detector. Settings are local
by default.

All settings need the `description` setting containing the user-facing
description of what the setting does. For example:

```ruby
@config = {
  ignore_columns: {
    description: "specific validators, written as Model(column1, column2, ...), that should not be checked"
  }
}
```

defines a local setting `ignore_columns` with a short description on how to use
the setting.

A setting can be made global by adding `global: true`. For example:

```ruby
@config = {
  ignore_models: {
    description: "models whose uniqueness validators should not be checked",
    global: true
  },
}
```

defines a global setting `ignore_models`.
