# frozen_string_literal: true

module ActiveRecordDoctor
  module Logger
    class Hierarchical # :nodoc:
      def initialize(io)
        @io = io
        @nesting = 0
      end

      def log(message)
        @io.puts("  " * @nesting + message.to_s)
        return if !block_given?

        @nesting += 1
        result = yield
        @nesting -= 1
        result
      end
    end
  end
end
