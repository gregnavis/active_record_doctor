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

          indexes.each do |index|
            next if config(:ignore_indexes).include?(index.name)

            replacement_indexes = indexes.select do |other_index|
              index != other_index && replacable_with?(index, other_index)
            end

            next if replacement_indexes.empty?

            problem!(
              extraneous_index: index.name,
              replacement_indexes: replacement_indexes.map(&:name).sort
            )
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

      def replacable_with?(index1, index2)
        return false if index1.type != index2.type
        return false if index1.using != index2.using
        return false if index1.where != index2.where
        return false if opclasses(index1) != opclasses(index2)

        case [index1.unique, index2.unique]
        when [true, true]
          index1.columns == index2.columns
        when [true, false]
          false
        else
          prefix?(index1, index2)
        end
      end

      def opclasses(index)
        index.respond_to?(:opclasses) ? index.opclasses : nil
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
