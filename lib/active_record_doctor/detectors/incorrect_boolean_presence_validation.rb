# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    class IncorrectBooleanPresenceValidation < Base # :nodoc:
      @description = "detect persence (instead of inclusion) validators on boolean columns"
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

      def message(model:, attribute:)
        # rubocop:disable Layout/LineLength
        "replace the `presence` validator on #{model}.#{attribute} with `inclusion` - `presence` can't be used on booleans"
        # rubocop:enable Layout/LineLength
      end

      def detect
        models(except: config(:ignore_models)).each do |model|
          next unless model.table_exists?

          connection.columns(model.table_name).each do |column|
            next if config(:ignore_attributes).include?("#{model.name}.#{column.name}")
            next unless column.type == :boolean
            next unless has_presence_validator?(model, column)

            problem!(model: model.name, attribute: column.name)
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
