# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    # Detect indexes whose function can be overtaken by other indexes. For example, an index on columns A, B, and C
    # can also serve as an index on A and A, B.
    class ExtraneousIndexes < Base
      @description = "Detect extraneous indexes"

      private

      def message(extraneous_index:, replacement_indexes:)
        if replacement_indexes.nil?
          "remove #{extraneous_index} - coincides with the primary key on the table"
        else
          "remove #{extraneous_index} - can be replaced by #{replacement_indexes.join(' or ')}"
        end
      end

      def detect
        subindexes_of_multi_column_indexes
        indexed_primary_keys
      end

      def subindexes_of_multi_column_indexes
        tables.each do |table|
          next if table == "schema_migrations"

          indexes = indexes(table)
          maximal_indexes = indexes.select do |index|
            maximal?(indexes, index)
          end

          indexes.each do |index|
            next if maximal_indexes.include?(index)

            replacement_indexes = maximal_indexes.select do |maximum_index|
              cover?(maximum_index, index)
            end.map(&:name).sort

            problem!(
              extraneous_index: index.name,
              replacement_indexes: replacement_indexes
            )
          end
        end
      end

      def indexed_primary_keys
        tables.each do |table|
          next if table == "schema_migrations"

          indexes(table).each do |index|
            next if index.columns != ["id"]

            problem!(
              extraneous_index: index.name,
              replacement_indexes: nil
            )
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
