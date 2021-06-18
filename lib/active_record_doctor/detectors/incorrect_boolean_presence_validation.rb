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
        eager_load!

        models.reject do |model|
          model.table_name.nil? ||
            model.table_name == "schema_migrations" ||
            !table_exists?(model.table_name)
        end.map do |model|
          [
            model.name,
            connection.columns(model.table_name).select do |column|
              column.type == :boolean &&
                has_presence_validator?(model, column)
            end.map(&:name)
          ]
        end.reject do |_model_name, columns|
          columns.empty?
        end.each do |model_name, columns|
          columns.each do |column|
            problem!(
              model: model_name,
              column: column
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
