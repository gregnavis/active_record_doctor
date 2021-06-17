# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    # Detect model-level presence validators on columns that lack a non-NULL constraint thus allowing potentially
    # invalid insertions.
    class MissingNonNullConstraint < Base
      @description = "Detect presence validators not backed by a non-NULL constraint"

      private

      def message(column:, model:, table:)
        "add `NOT NULL` to #{table}.#{column} - #{model} validates its presence but it's not non-NULL in the database"
      end

      def detect
        eager_load!

        problems(models.reject do |model|
          model.table_name.nil? ||
          model.table_name == "schema_migrations" ||
          !table_exists?(model.table_name)
        end.map do |model|
          [
            model,
            connection.columns(model.table_name).select do |column|
              validator_needed?(model, column) &&
                has_mandatory_presence_validator?(model, column) &&
                column.null
            end.map(&:name)
          ]
        end.flat_map do |model, columns|
          columns.map do |column|
            {
              column: column,
              model: model.name,
              table: model.table_name
            }
          end
        end)
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
