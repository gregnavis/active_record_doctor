# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    # Find instances of boolean column presence validations that use presence/absence instead of includes/excludes.
    class IncorrectBooleanPresenceValidation < Base
      @description = "Detect boolean columns with presence instead of includes validators"

      private

      def message(model:, column:)
        "replace the `presence` validator on #{model}.#{column} with `inclusion` - `presence` can't be used on booleans"
      end

      def detect
        models.each do |model|
          next if model.table_name.nil?
          next if model.table_name == "schema_migrations"
          next unless table_exists?(model.table_name)

          connection.columns(model.table_name).each do |column|
            next unless column.type == :boolean
            next unless has_presence_validator?(model, column)

            problem!(
              model: model.name,
              column: column.name
            )
          end
        end
      end

      def has_presence_validator?(model, column)
        model.validators.any? do |validator|
          validator.kind == :presence && validator.attributes.include?(column.name.to_sym)
        end
      end
    end
  end
end
