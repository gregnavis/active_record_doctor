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
        }
      }

      private

      def message(column:, model:)
        "add a `presence` validator to #{model}.#{column} - it's NOT NULL but lacks a validator"
      end

      def detect
        models(except: config(:ignore_models)).each do |model|
          next unless model.table_exists?

          connection.columns(model.table_name).each do |column|
            next unless validator_needed?(model, column)
            next if validator_present?(model, column)
            next if config(:ignore_attributes).include?("#{model}.#{column.name}")

            problem!(column: column.name, model: model.name)
          end
        end
      end

      def validator_needed?(model, column)
        ![model.primary_key, "created_at", "updated_at"].include?(column.name) &&
          !column.null
      end

      def validator_present?(model, column)
        if column.type == :boolean
          inclusion_validator_present?(model, column) ||
            exclusion_validator_present?(model, column)
        else
          presence_validator_present?(model, column)
        end
      end

      def inclusion_validator_present?(model, column)
        model.validators.any? do |validator|
          validator.is_a?(ActiveModel::Validations::InclusionValidator) &&
            validator.attributes.include?(column.name.to_sym) &&
            !validator.options.fetch(:in, []).include?(nil)
        end
      end

      def exclusion_validator_present?(model, column)
        model.validators.any? do |validator|
          validator.is_a?(ActiveModel::Validations::ExclusionValidator) &&
            validator.attributes.include?(column.name.to_sym) &&
            validator.options.fetch(:in, []).include?(nil)
        end
      end

      def presence_validator_present?(model, column)
        allowed_attributes = [column.name.to_sym]

        belongs_to = model.reflect_on_all_associations(:belongs_to).find do |reflection|
          reflection.foreign_key == column.name
        end
        allowed_attributes << belongs_to.name.to_sym if belongs_to

        model.validators.any? do |validator|
          validator.is_a?(ActiveRecord::Validations::PresenceValidator) &&
            (validator.attributes & allowed_attributes).present?
        end
      end
    end
  end
end
