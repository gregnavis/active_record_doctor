# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    class MissingNonNullConstraint < Base # :nodoc:
      @description = "detect presence validators not backed by a non-NULL constraint"
      @config = {
        ignore_models: {
          description: "models whose presence validators should not be checked",
          global: true
        },
        ignore_attributes: {
          description: "attributes, written as Model.attribute, whose presence validators should not be checked"
        }
      }

      private

      def message(column:, model:, table:)
        "add `NOT NULL` to #{table}.#{column} - #{model} validates its presence but it's not non-NULL in the database"
      end

      def detect
        models(except: config(:ignore_models)).each do |model|
          next if model.table_name.nil?
          next unless table_exists?(model.table_name)

          connection.columns(model.table_name).each do |column|
            next if config(:ignore_attributes).include?("#{model.name}.#{column.name}")
            next unless validator_needed?(model, column)
            next unless has_mandatory_presence_validator?(model, column)
            next unless column.null

            problem!(
              column: column.name,
              model: model.name,
              table: model.table_name
            )
          end
        end
      end

      def validator_needed?(model, column)
        ![model.primary_key, "created_at", "updated_at"].include?(column.name)
      end

      def has_mandatory_presence_validator?(model, column)
        # A foreign key can be validates via the column name (e.g. company_id)
        # or the association name (e.g. company). We collect the allowed names
        # in an array to check for their presence in the validator definition
        # in one go.
        attribute_name_forms = [column.name.to_sym]
        belongs_to = model.reflect_on_all_associations(:belongs_to).find do |reflection|
          reflection.foreign_key == column.name
        end
        attribute_name_forms << belongs_to.name.to_sym if belongs_to

        model.validators.any? do |validator|
          validator.is_a?(ActiveRecord::Validations::PresenceValidator) &&
            (validator.attributes & attribute_name_forms).present? &&
            !validator.options[:allow_nil] &&
            !validator.options[:if] &&
            !validator.options[:unless]
        end
      end
    end
  end
end
