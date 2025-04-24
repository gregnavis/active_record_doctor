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
        each_model(except: config(:ignore_models), existing_tables_only: true) do |model|
          each_attribute(model, except: config(:ignore_attributes), type: [:string, :text]) do |column|
            model_maximum = maximum_allowed_by_validations(model, column.name.to_sym)
            next if model_maximum == column.limit

            # Add violation only to the root model of STI.
            next if (model_maximum.nil? || column.limit.nil?) && sti_subclass?(model)

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

      def sti_subclass?(model)
        model.columns_hash.include?(model.inheritance_column.to_s) &&
          model.base_class != model
      end
    end
  end
end
