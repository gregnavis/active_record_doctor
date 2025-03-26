# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    class MissingPresenceValidation < Base # :nodoc:
      @description = "detect non-NULL columns without a corresponding presence validator"
      @config = {
        ignore_models: {
          description: "models whose underlying tables' columns should not be checked",
          global: true
        },
        ignore_attributes: {
          description: "specific attributes, written as Model.attribute, that should not be checked"
        },
        ignore_columns_with_default: {
          description: "ignore columns with default values, should be provided as boolean"
        }
      }

      private

      def message(column:, model:)
        "add a `presence` validator to #{model}.#{column} - it's NOT NULL but lacks a validator"
      end

      def detect
        each_model(except: config(:ignore_models), existing_tables_only: true) do |model|
          each_attribute(model, except: config(:ignore_attributes)) do |column|
            next unless validator_needed?(model, column)
            next if validator_present?(model, column)
            next if counter_cache_column?(model, column)

            problem!(column: column.name, model: model.name)
          end
        end
      end

      def validator_needed?(model, column)
        ![model.primary_key, "created_at", "updated_at", "created_on", "updated_on"].include?(column.name) &&
          (!column.null || not_null_check_constraint_exists?(model.table_name, column)) &&
          !default_value_instead_of_validation?(column)
      end

      def default_value_instead_of_validation?(column)
        (!column.default.nil? || column.default_function) && config(:ignore_columns_with_default)
      end

      def validator_present?(model, column)
        inclusion_validator_present?(model, column) ||
          exclusion_validator_present?(model, column) ||
          presence_validator_present?(model, column)
      end

      def inclusion_validator_present?(model, column)
        model.validators.any? do |validator|
          validator_items = inclusion_validator_items(validator)
          return true if validator_items.is_a?(Proc)

          attributes = validator.attributes.map(&:to_s)
          validator.is_a?(ActiveModel::Validations::InclusionValidator) &&
            attributes.include?(column.name) &&
            !validator_items.include?(nil)
        end
      end

      def exclusion_validator_present?(model, column)
        model.validators.any? do |validator|
          validator_items = inclusion_validator_items(validator)
          return true if validator_items.is_a?(Proc)

          attributes = validator.attributes.map(&:to_s)
          validator.is_a?(ActiveModel::Validations::ExclusionValidator) &&
            attributes.include?(column.name) &&
            validator_items.include?(nil)
        end
      end

      def presence_validator_present?(model, column)
        allowed_attributes = [column.name]

        belongs_to = model.reflect_on_all_associations(:belongs_to).find do |reflection|
          reflection.foreign_key == column.name
        end
        allowed_attributes << belongs_to.name.to_s if belongs_to

        model.validators.any? do |validator|
          attributes = validator.attributes.map(&:to_s)

          validator.is_a?(ActiveRecord::Validations::PresenceValidator) &&
            (attributes & allowed_attributes).present?
        end
      end

      def inclusion_validator_items(validator)
        validator.options[:in] || validator.options[:within] || []
      end

      def counter_cache_column?(model, column)
        model.reflect_on_all_associations(:has_many).any? do |reflection|
          reflection.has_cached_counter? && reflection.counter_cache_column == column.name
        end
      end
    end
  end
end
