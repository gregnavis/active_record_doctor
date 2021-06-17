# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    # Find foreign-key like columns lacking an actual foreign key constraint.
    class MissingForeignKeys < Base
      private

      @description = "Detect association columns without a foreign key constraint"

      def message(table:, column:)
        "create a foreign key on #{table}.#{column} - looks like an association without a foreign key constraint"
      end

      def detect
        problems(tables.reject do |table|
          table == "schema_migrations"
        end.map do |table|
          [
            table,
            connection.columns(table).select do |column|
              # We need to skip polymorphic associations as they can reference
              # multiple tables but a foreign key constraint can reference
              # a single predefined table.
              named_like_foreign_key?(column) &&
                !foreign_key?(table, column) &&
                !polymorphic_foreign_key?(table, column)
            end.map(&:name)
          ]
        end.reject do |_table, columns|
          columns.empty?
        end.flat_map do |table, columns|
          columns.map do |column|
            { table: table, column: column }
          end
        end)
      end

      def named_like_foreign_key?(column)
        column.name.end_with?("_id")
      end

      def foreign_key?(table, column)
        connection.foreign_keys(table).any? do |foreign_key|
          foreign_key.options[:column] == column.name
        end
      end

      def polymorphic_foreign_key?(table, column)
        type_column_name = column.name.sub(/_id\Z/, "_type")
        connection.columns(table).any? do |another_column|
          another_column.name == type_column_name
        end
      end
    end
  end
end
