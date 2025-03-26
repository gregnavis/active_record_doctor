# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    class IncorrectBooleanPresenceValidation < Base # :nodoc:
      @description = "detect presence (instead of inclusion) validators on boolean columns"
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
        each_model(except: config(:ignore_models), existing_tables_only: true) do |model|
          each_attribute(model, except: config(:ignore_attributes)) do |column|
            next unless column.type == :boolean
            next unless has_presence_validator?(model, column)

            problem!(model: model.name, attribute: column.name)
          end
        end
      end

      def has_presence_validator?(model, column)
        model.validators.any? do |validator|
          attributes = validator.attributes.map(&:to_s)
          validator.kind == :presence && attributes.include?(column.name)
        end
      end
    end
  end
end
