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
    end
  end
end
