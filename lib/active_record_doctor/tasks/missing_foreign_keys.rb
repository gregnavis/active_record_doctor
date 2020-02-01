require "active_record_doctor/tasks/base"

module ActiveRecordDoctor
  module Tasks
    class MissingForeignKeys < Base
      @description = 'Detect association columns without a foreign key constraint'

      def run
        success(hash_from_pairs(tables.select do |table|
          "schema_migrations" != table
        end.map do |table|
          [
            table,
            connection.columns(table).select do |column|
              # We need to skip polymorphic associations as they can reference
              # multiple tables but a foreign key constraint can reference
              # a single predefined table.
              id?(table, column) &&
                !foreign_key?(table, column) &&
                !polymorphic_foreign_key?(table, column)
            end.map(&:name)
          ]
        end.select do |table, columns|
          !columns.empty?
        end))
      end

      private

      def id?(table, column)
        column.name.end_with?("_id")
      end

      def foreign_key?(table, column)
        connection.foreign_keys(table).any? do |foreign_key|
          foreign_key.options[:column] == column.name
        end
      end

      def polymorphic_foreign_key?(table, column)
        type_column_name = column.name.sub(/_id\Z/, '_type')
        connection.columns(table).any? do |another_column|
          another_column.name == type_column_name
        end
      end
    end
  end
end
