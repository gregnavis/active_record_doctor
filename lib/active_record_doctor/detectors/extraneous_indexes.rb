# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    class ExtraneousIndexes < Base # :nodoc:
      @description = "identify indexes that can be dropped without degrading performance"
      @config = {
        ignore_tables: {
          description: "tables whose indexes should never be reported as extraneous",
          global: true
        },
        ignore_indexes: {
          description: "indexes that should never be reported as extraneous",
          global: true
        }
      }

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
        tables(except: config(:ignore_tables)).each do |table|
          indexes = indexes(table)
          maximal_indexes = indexes.select { |index| maximal?(indexes, index) }

          indexes.each do |index|
            next if maximal_indexes.include?(index)

            replacement_indexes = maximal_indexes.select do |maximum_index|
              cover?(maximum_index, index)
            end.map(&:name).sort

            next if config(:ignore_indexes).include?(index.name)

            problem!(extraneous_index: index.name, replacement_indexes: replacement_indexes)
          end
        end
      end

      def indexed_primary_keys
        tables(except: config(:ignore_tables)).each do |table|
          indexes(table).each do |index|
            next if config(:ignore_indexes).include?(index.name)
            next if index.columns != ["id"]

            problem!(extraneous_index: index.name, replacement_indexes: nil)
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
        return false unless compatible_options?(lhs, rhs)

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

      def compatible_options?(lhs, rhs)
        lhs.type == rhs.type &&
          lhs.using == rhs.using &&
          lhs.where == rhs.where &&
          same_opclasses?(lhs, rhs)
      end

      def same_opclasses?(lhs, rhs)
        if ActiveRecord::VERSION::STRING >= "5.2"
          rhs.columns.all? do |column|
            lhs_opclass = lhs.opclasses.is_a?(Hash) ? lhs.opclasses[column] : lhs.opclasses
            rhs_opclass = rhs.opclasses.is_a?(Hash) ? rhs.opclasses[column] : rhs.opclasses
            lhs_opclass == rhs_opclass
          end
        else
          true
        end
      end
    end
  end
end
