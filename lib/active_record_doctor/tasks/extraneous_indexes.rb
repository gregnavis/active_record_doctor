# frozen_string_literal: true

require "active_record_doctor/tasks/base"

module ActiveRecordDoctor
  module Tasks
    # Detect indexes whose function can be overtaken by other indexes. For example, an index on columns A, B, and C
    # can also serve as an index on A and A, B.
    class ExtraneousIndexes < Base
      @description = "Detect extraneous indexes"

      def run
        success(subindexes_of_multi_column_indexes + indexed_primary_keys)
      end

      private

      def subindexes_of_multi_column_indexes
        tables.reject do |table|
          table == "schema_migrations"
        end.flat_map do |table|
          indexes = indexes(table)
          maximum_indexes = indexes.select do |index|
            maximal?(indexes, index)
          end

          indexes.reject do |index|
            maximum_indexes.include?(index)
          end.map do |extraneous_index|
            [
              extraneous_index.name,
              [
                :multi_column,
                maximum_indexes.select do |maximum_index|
                  cover?(maximum_index, extraneous_index)
                end.map(&:name).sort
              ].flatten(1)
            ]
          end
        end
      end

      def indexed_primary_keys
        @indexed_primary_keys ||= tables.reject do |table|
          table == "schema_migrations"
        end.map do |table|
          [
            table,
            indexes(table).select do |index|
              index.columns == ["id"]
            end
          ]
        end.flat_map do |table, indexes|
          indexes.map do |index|
            [index.name, [:primary_key, table]]
          end
        end
      end

      def maximal?(indexes, index)
        indexes.all? do |another_index|
          index == another_index || !cover?(another_index, index)
        end
      end

      # Does lhs cover rhs?
      def cover?(lhs, rhs)
        case [lhs.unique, rhs.unique]
        when [true, true]
          lhs.columns == rhs.columns
        when [false, true]
          false
        else
          prefix?(rhs, lhs)
        end
      end

      def prefix?(lhs, rhs)
        lhs.columns.count <= rhs.columns.count &&
          rhs.columns[0...lhs.columns.count] == lhs.columns
      end

      def indexes(table_name)
        super.select { |index| index.columns.is_a?(Array) }
      end
    end
  end
end
