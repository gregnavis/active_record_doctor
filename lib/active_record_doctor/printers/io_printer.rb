# frozen_string_literal: true

module ActiveRecordDoctor
  module Printers
    # Default printer for displaying messages produced by active_record_doctor.
    class IOPrinter
      def initialize(io = $stdout)
        @io = io
      end

      def unindexed_foreign_keys(unindexed_foreign_keys, _options)
        return if unindexed_foreign_keys.empty?

        @io.puts("The following foreign keys should be indexed for performance reasons:")
        @io.puts(unindexed_foreign_keys.sort.map do |table, columns|
          "  #{table} #{columns.sort.join(' ')}"
        end.join("\n"))
      end

      def extraneous_indexes(extraneous_indexes, _options)
        return if extraneous_indexes.empty?

        @io.puts("The following indexes are extraneous and can be removed:")
        extraneous_indexes.each do |index, details|
          reason, *params = details
          case reason
          when :multi_column
            @io.puts("  #{index} (can be handled by #{params.join(', ')})")
          when :primary_key
            @io.puts("  #{index} (is a primary key of #{params[0]})")
          else
            raise("unknown reason #{reason.inspect}")
          end
        end
      end

      def missing_foreign_keys(missing_foreign_keys, _options)
        return if missing_foreign_keys.empty?

        @io.puts("The following columns lack a foreign key constraint:")
        @io.puts(missing_foreign_keys.sort.map do |table, columns|
          "  #{table} #{columns.sort.join(' ')}"
        end.join("\n"))
      end

      def undefined_table_references(models, options)
        return if models.empty?

        unless options.fetch(:views_checked)
          @io.puts(<<WARNING)
WARNING: Models backed by database views are supported only in Rails 5+ OR
Rails 4.2 + PostgreSQL. It seems this is NOT your setup. Therefore, such models
will be erroneously reported below as not having their underlying tables/views.
Consider upgrading Rails or disabling this task temporarily.
WARNING
        end

        @io.puts("The following models reference undefined tables:")
        models.each do |model_name, table_name|
          @io.puts("  #{model_name} (the table #{table_name} is undefined)")
        end
      end

      def unindexed_deleted_at(indexes, _options)
        return if indexes.empty?

        @io.puts("The following indexes should include `deleted_at IS NULL`:")
        indexes.each do |index|
          @io.puts("  #{index}")
        end
      end

      def missing_unique_indexes(indexes, _options)
        return if indexes.empty?

        @io.puts("The following indexes should be created to back model-level uniqueness validations:")
        indexes.each do |table, arrays_of_columns|
          arrays_of_columns.each do |columns|
            @io.puts("  #{table}: #{columns.join(', ')}")
          end
        end
      end

      def missing_presence_validation(missing_presence_validators, _options)
        return if missing_presence_validators.empty?

        @io.puts("The following models and columns should have presence validations:")
        missing_presence_validators.each do |model_name, array_of_columns|
          @io.puts("  #{model_name}: #{array_of_columns.join(', ')}")
        end
      end

      def missing_non_null_constraint(missing_non_null_constraints, _options)
        return if missing_non_null_constraints.empty?

        @io.puts("The following columns should be marked as `null: false`:")
        missing_non_null_constraints.each do |table, columns|
          @io.puts("  #{table}: #{columns.join(', ')}")
        end
      end

      def incorrect_boolean_presence_validation(incorrect_boolean_presence_validations, _options)
        return if incorrect_boolean_presence_validations.empty?

        @io.puts("The presence of the following boolean columns is validated incorrectly:")
        incorrect_boolean_presence_validations.each do |table, columns|
          @io.puts("  #{table}: #{columns.join(', ')}")
        end
      end

      def incorrect_dependent_option(problems, _options)
        return if problems.empty?

        @io.puts("The following associations might be using invalid dependent settings:")
        problems.each do |model, associations|
          associations.each do |(name, problem)|
            # rubocop:disable Layout/LineLength
            message =
              case problem
              when :suggest_destroy then "skips callbacks that are defined on the associated model - consider changing to `dependent: :destroy` or similar"
              when :suggest_delete then "loads the associated model before deleting it - consider using `dependent: :delete`"
              when :suggest_delete_all then "loads models one-by-one to invoke callbacks even though the related model defines none - consider using `dependent: :delete_all`"
              else next
              end
            # rubocop:enable Layout/LineLength

            @io.puts("  #{model}: #{name} #{message}")
          end
        end
      end
    end
  end
end
