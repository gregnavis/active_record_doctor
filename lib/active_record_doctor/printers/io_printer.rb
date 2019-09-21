module ActiveRecordDoctor
  module Printers
    class IOPrinter
      def initialize(io = STDOUT)
        @io = io
      end

      def unindexed_foreign_keys(unindexed_foreign_keys)
        @io.puts(unindexed_foreign_keys.sort.map do |table, columns|
          "#{table} #{columns.sort.join(' ')}"
        end.join("\n"))
      end

      def extraneous_indexes(extraneous_indexes)
        if extraneous_indexes.empty?
          @io.puts("No indexes are extraneous.")
        else
          @io.puts("The following indexes are extraneous and can be removed:")
          extraneous_indexes.each do |index, details|
            reason, *params = details
            case reason
            when :multi_column
              @io.puts("  #{index} (can be handled by #{params.join(', ')})")
            when :primary_key
              @io.puts("  #{index} (is a primary key of #{params[0]})")
            else
              fail("unknown reason #{reason.inspect}")
            end
          end
        end
      end

      def missing_foreign_keys(missing_foreign_keys)
        @io.puts(missing_foreign_keys.sort.map do |table, columns|
          "#{table} #{columns.sort.join(' ')}"
        end.join("\n"))
      end

      def undefined_table_references(models)
        return if models.empty?

        @io.puts('The following models reference undefined tables:')
        models.each do |model|
          @io.puts("  #{model.name} (the table #{model.table_name} is undefined)")
        end
      end

      def unindexed_deleted_at(indexes)
        return if indexes.empty?

        @io.puts('The following indexes should include `deleted_at IS NULL`:')
        indexes.each do |index|
          @io.puts("  #{index}")
        end
      end

      def missing_unique_indexes(indexes)
        return if indexes.empty?

        @io.puts('The following indexes should be created to back model-level uniqueness validations:')
        indexes.each do |table, arrays_of_columns|
          arrays_of_columns.each do |columns|
            @io.puts("  #{table}: #{columns.join(', ')}")
          end
        end
      end

      def missing_presence_validation(missing_presence_validators)
        return if missing_presence_validators.empty?

        @io.puts('The following models and columns should have presence validations:')
        missing_presence_validators.each do |model_name, array_of_columns|
          @io.puts("  #{model_name}: #{array_of_columns.join(', ')}")
        end
      end

      def missing_non_null_constraint(missing_non_null_constraints)
        return if missing_non_null_constraints.empty?

        @io.puts('The following columns should be marked as `null: false`:')
        missing_non_null_constraints.each do |table, columns|
          @io.puts("  #{table}: #{columns.join(', ')}")
        end
      end

      def presence_true_on_boolean(presence_true_on_booleans)
        return if presence_true_on_booleans.empty?

        @io.puts('The presence of the following boolean columns is validated incorrectly:')
        presence_true_on_booleans.each do |table, columns|
          @io.puts("  #{table}: #{columns.join(', ')}")
        end
      end
    end
  end
end
