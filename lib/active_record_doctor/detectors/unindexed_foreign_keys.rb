# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    # Find foreign keys that lack indexes (usually recommended for performance reasons).
    class UnindexedForeignKeys < Base
      @description = "Detect foreign keys without an index on them"

      def detect
        problems(hash_from_pairs(tables.reject do |table|
          table == "schema_migrations"
        end.map do |table|
          [
            table,
            connection.columns(table).select do |column|
              foreign_key?(column) &&
                !indexed?(table, column) &&
                !indexed_as_polymorphic?(table, column)
            end.map(&:name)
          ]
        end.reject do |_table, columns|
          columns.empty?
        end))
      end

      private

      def foreign_key?(column)
        column.name.end_with?("_id")
      end

      def indexed?(table, column)
        connection.indexes(table).any? do |index|
          index.columns.first == column.name
        end
      end

      def indexed_as_polymorphic?(table, column)
        type_column_name = column.name.sub(/_id\Z/, "_type")
        connection.indexes(table).any? do |index|
          index.columns == [type_column_name, column.name]
        end
      end
    end
  end
end
