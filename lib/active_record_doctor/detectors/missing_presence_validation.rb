# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    # Detect models with non-NULL columns that lack the corresponding model-level validator.
    class MissingPresenceValidation < Base
      @description = "Detect non-NULL columns without a presence validator"

      private

      def message(column:, model:)
        "add a `presence` validator to #{model}.#{column} - it's NOT NULL but lacks a validator"
      end

      def detect
        eager_load!

        models.each do |model|
          next if model.table_name.nil?
          next if model.table_name == "schema_migrations"
          next unless table_exists?(model.table_name)

          connection.columns(model.table_name).each do |column|
            next unless validator_needed?(model, column)
            next if validator_present?(model, column)

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
