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

      def message(table:, extraneous_index:, replacement_indexes:)
        if replacement_indexes.nil?
          "remove #{extraneous_index} from #{table} - coincides with the primary key on the table"
        else
          # rubocop:disable Layout/LineLength
          "remove the index #{extraneous_index} from the table #{table} - queries should be able to use the following #{'index'.pluralize(replacement_indexes.count)} instead: #{replacement_indexes.join(' or ')}"
          # rubocop:enable Layout/LineLength
        end
      end

      def detect
        subindexes_of_multi_column_indexes
        indexed_primary_keys
      end

      def subindexes_of_multi_column_indexes
        log(__method__) do
          each_data_source(except: config(:ignore_tables)) do |table|
            each_index(table, except: config(:ignore_indexes), multicolumn_only: true) do |index, indexes|
              replacement_indexes = indexes.select do |other_index|
                index != other_index && replaceable_with?(index, other_index)
              end

              if replacement_indexes.empty?
                log("Found no replacement indexes; skipping")
                next
              end

              problem!(
                table: table,
                extraneous_index: index.name,
                replacement_indexes: replacement_indexes.map(&:name).sort
              )
            end
          end
        end
      end

      def indexed_primary_keys
        log(__method__) do
          each_table(except: config(:ignore_tables)) do |table|
            each_index(table, except: config(:ignore_indexes), multicolumn_only: true) do |index|
              primary_key = connection.primary_key(table)
              if index.columns == [primary_key] && index.where.nil?
                problem!(table: table, extraneous_index: index.name, replacement_indexes: nil)
              end
            end
          end
        end
      end

      def replaceable_with?(index1, index2)
        return false if index1.type != index2.type
        return false if index1.using != index2.using
        return false if index1.where != index2.where
        return false if opclasses(index1) != opclasses(index2)

        case [index1.unique, index2.unique]
        when [true, true]
          (index2.columns - index1.columns).empty?
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
    end
  end
end
