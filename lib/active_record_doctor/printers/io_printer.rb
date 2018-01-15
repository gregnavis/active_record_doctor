module ActiveRecordDoctor
  module Printers
    class IOPrinter
      def initialize(io: STDOUT)
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
    end
  end
end
