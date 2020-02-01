require "active_record_doctor/tasks/base"

module ActiveRecordDoctor
  module Tasks
    class UnindexedForeignKeys < Base
      @description = 'Detect foreign keys without an index on them'

      def run
        success(hash_from_pairs(tables.select do |table|
          "schema_migrations" != table
        end.map do |table|
          [
            table,
            connection.columns(table).select do |column|
              foreign_key?(table, column) &&
                !indexed?(table, column) &&
                !indexed_as_polymorphic?(table, column)
            end.map(&:name)
          ]
        end.select do |table, columns|
          !columns.empty?
        end))
      end

      private

      def foreign_key?(table, column)
        column.name.end_with?("_id")
      end

      def indexed?(table, column)
        connection.indexes(table).any? do |index|
          index.columns.first == column.name
        end
      end

      def indexed_as_polymorphic?(table, column)
        type_column_name = column.name.sub(/_id\Z/, '_type')
        connection.indexes(table).any? do |index|
          index.columns == [type_column_name, column.name]
        end
      end
    end
  end
end
