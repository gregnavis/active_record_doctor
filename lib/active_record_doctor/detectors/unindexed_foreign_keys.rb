# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    # Find foreign keys that lack indexes (usually recommended for performance reasons).
    class UnindexedForeignKeys < Base
      @description = "Detect foreign keys without an index on them"

      private

      def message(table:, column:)
        # rubocop:disable Layout/LineLength
        "add an index on #{table}.#{column} - foreign keys are often used in database lookups and should be indexed for performance reasons"
        # rubocop:enable Layout/LineLength
      end

      def detect
        tables.each do |table|
          next if table == "schema_migrations"

          connection.columns(table).each do |column|
            next unless foreign_key?(column)
            next if indexed?(table, column)
            next if indexed_as_polymorphic?(table, column)

            problem!(table: table, column: column.name)
          end
        end
      end

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
