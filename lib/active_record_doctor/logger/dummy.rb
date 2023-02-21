# frozen_string_literal: true

module ActiveRecordDoctor
  module Logger
    class Dummy # :nodoc:
      def log(_message)
        yield if block_given?
      end
    end
  end
end
