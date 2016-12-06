module ActiveRecordDoctor
  module Printers
    class IOPrinter
      def initialize(io: STDOUT)
        @io = io
      end

      def print_unindexed_foreign_keys(unindexed_foreign_keys)
        @io.puts(unindexed_foreign_keys.sort.map do |table, columns|
          "#{table} #{columns.sort.join(' ')}"
        end.join("\n"))
      end

      def print_extraneous_indexes(extraneous_indexes)
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

      def print_missing_foreign_keys(missing_foreign_keys)
        @io.puts(missing_foreign_keys.sort.map do |table, columns|
          "#{table} #{columns.sort.join(' ')}"
        end.join("\n"))
      end
    end
  end
end
