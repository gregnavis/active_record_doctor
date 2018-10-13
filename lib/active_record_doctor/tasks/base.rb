require "active_record_doctor/printers/io_printer"

module ActiveRecordDoctor
  module Tasks
    class Base
      def self.run
        new.run
      end

      def initialize(printer = ActiveRecordDoctor::Printers::IOPrinter.new)
        @printer = printer
      end

      private

      def success(result)
        [result, true]
      end

      def connection
        @connection ||= ActiveRecord::Base.connection
      end

      def indexes(table_name)
        connection.indexes(table_name)
      end

      def tables
        @tables ||=
          if Rails::VERSION::MAJOR == 5
            connection.data_sources
          else
            connection.tables
          end
      end

      def hash_from_pairs(pairs)
        Hash[*pairs.flatten(1)]
      end

      def eager_load!
        # We call GC.start to make the test suite work. It's (probably) not
        # needed for use during development. However, if we remove it then the
        # test suite will start accumulating temporary model classes in the
        # object space. Running the garbage collector gets rid of them.
        GC.start

        Rails.application.eager_load!
      end

      def models
        descendants(ActiveRecord::Base)
      end

      def descendants(superclass)
        if Rails::VERSION::MAJOR == 5
          # It seems that temporary classes created by Temping don't play nicely
          # with Rails 5 descendant tracking. We use ObjectSpace for a more robust
          # implementation that works both in the test and development
          # environments.
          klasses = []
          ObjectSpace.each_object(Class) do |klass|
            klasses << klass if descendant?(klass, superclass)
          end
          klasses
        else
          superclass.descendants
        end
      end

      def descendant?(klass, superclass)
        !klass.nil? && (klass.superclass == superclass || descendant?(klass.superclass, superclass))
      end
    end
  end
end
