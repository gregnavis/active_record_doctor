require "active_record_doctor/compatibility"
require "active_record_doctor/printers/io_printer"

module ActiveRecordDoctor
  module Tasks
    class UndefinedTableReferences
      include Compatibility

      def self.run
        new.run
      end

      def initialize(printer: ActiveRecordDoctor::Printers::IOPrinter.new)
        @printer = printer
      end

      def run
        @printer.print_undefined_table_references(undefined_table_references)
        undefined_table_references.present? ? 1 : 0
      end

      private

      def undefined_table_references
        Rails.application.eager_load!

        ActiveRecord::Base.descendants.select do |model|
          model.table_name.present? &&
            !model.connection.tables.include?(model.table_name)
        end
      end
    end
  end
end
