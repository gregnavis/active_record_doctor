# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    # Detect columns covered by a uniqueness validation that lack the corresponding unique index thus risking duplicate
    # inserts.
    class MissingUniqueIndexes < Base
      @description = "Detect columns covered by a uniqueness validator without a unique index"

      private

      def message(table:, columns:)
        # rubocop:disable Layout/LineLength
        "add a unique index on #{table}(#{columns.join(', ')}) - validating uniqueness in the model without an index can lead to duplicates"
        # rubocop:enable Layout/LineLength
      end

      def detect
        eager_load!

        problems(models.reject do |model|
          model.table_name.nil?
        end.map do |model|
          [
            model.table_name,
            model.validators.select do |validator|
              table_name = model.table_name
              scope = validator.options.fetch(:scope, [])

              validator.is_a?(ActiveRecord::Validations::UniquenessValidator) &&
                supported_validator?(validator) &&
                !unique_index?(table_name, validator.attributes, scope)
            end.map do |validator|
              scope = Array(validator.options.fetch(:scope, []))
              attributes = validator.attributes
              (scope + attributes).map(&:to_s)
            end
          ]
        end.reject do |_table_name, indexes|
          indexes.empty?
        end.flat_map do |table_name, indexes|
          indexes.map do |columns|
            {
              table: table_name,
              columns: columns
            }
          end
        end)
      end

      def supported_validator?(validator)
        validator.options[:if].nil? &&
          validator.options[:unless].nil? &&
          validator.options[:conditions].nil? &&

          # In Rails 6, default option values are no longer explicitly set on
          # options so if the key is absent we must fetch the default value
          # ourselves. case_sensitive is the default in 4.2+ so it's safe to
          # put true literally.
          validator.options.fetch(:case_sensitive, true)
      end

      def unique_index?(table_name, columns, scope)
        columns = (Array(scope) + columns).map(&:to_s)

        indexes(table_name).any? do |index|
          index.columns.to_set == columns.to_set && index.unique
        end
      end
    end
  end
end
