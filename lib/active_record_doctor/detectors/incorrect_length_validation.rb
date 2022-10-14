# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    class IncorrectLengthValidation < Base # :nodoc:
      @description = "detect mismatches between database length limits and model length validations"
      @config = {
        ignore_models: {
          description: "models whose validators should not be checked",
          global: true
        },
        ignore_attributes: {
          description: "attributes, written as Model.attribute, whose validators should not be checked"
        }
      }

      private

      def message(model:, attribute:, table:, database_maximum:, model_maximum:)
        # rubocop:disable Layout/LineLength
        if database_maximum && model_maximum
          "the schema limits #{table}.#{attribute} to #{database_maximum} characters but the length validator on #{model}.#{attribute} enforces a maximum of #{model_maximum} characters - set both limits to the same value or remove both"
        elsif database_maximum && model_maximum.nil?
          "the schema limits #{table}.#{attribute} to #{database_maximum} characters but there's no length validator on #{model}.#{attribute} - remove the database limit or add the validator"
        elsif database_maximum.nil? && model_maximum
          "the length validator on #{model}.#{attribute} enforces a maximum of #{model_maximum} characters but there's no schema limit on #{table}.#{attribute} - remove the validator or the schema length limit"
        end
        # rubocop:enable Layout/LineLength
      end

      def detect
        models(except: config(:ignore_models)).each do |model|
          next unless model.table_exists?

          connection.columns(model.table_name).each do |column|
            next if config(:ignore_attributes).include?("#{model.name}.#{column.name}")
            next if ![:string, :text].include?(column.type)

            model_maximum = maximum_allowed_by_validations(model, column.name.to_sym)
            next if model_maximum == column.limit

            problem!(
              model: model.name,
              attribute: column.name,
              table: model.table_name,
              database_maximum: column.limit,
              model_maximum: model_maximum
            )
          end
        end
      end

      def maximum_allowed_by_validations(model, column)
        length_validator = model.validators.find do |validator|
          validator.kind == :length &&
            validator.options.include?(:maximum) &&
            validator.attributes.include?(column)
        end
        length_validator ? length_validator.options[:maximum] : nil
      end
    end
  end
end
