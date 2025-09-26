# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    class MissingForeignKeys < Base # :nodoc:
      @description = "detect foreign-key-like columns lacking an actual foreign key constraint"
      @config = {
        ignore_models: {
          description: "models whose columns should not be checked",
          global: true
        },
        ignore_associations: {
          description: "associations, written as Model.association, that should not be checked"
        }
      }

      private

      def message(table:, column:)
        "create a foreign key on #{table}.#{column} - looks like an association without a foreign key constraint"
      end

      def detect
        each_model(except: config(:ignore_models), existing_tables_only: true) do |model|
          foreign_keys = connection.foreign_keys(model.table_name)
          foreign_key_columns = foreign_keys.map { |key| key.options[:column] }

          each_association(model, type: :belongs_to) do |association|
            next if ignored?("#{model.name}.#{association.name}", config(:ignore_associations))
            next if association.options[:polymorphic]

            has_foreign_key = foreign_key_columns.include?(association.foreign_key)
            next if has_foreign_key

            problem!(table: model.table_name, column: association.foreign_key)
          end
        end
      end
    end
  end
end
