require "active_record_doctor/tasks/base"

module ActiveRecordDoctor
  module Tasks
    class MissingPresenceValidation < Base
      def run
        eager_load!

        success(hash_from_pairs(models.reject do |model|
          model.table_name.nil? || model.table_name == 'schema_migrations'
        end.map do |model|
          [
            model.name,
            connection.columns(model.table_name).select do |column|
              validator_needed?(model, column) &&
                !validator_present?(model, column)
            end.map(&:name)
          ]
        end.reject do |model_name, columns|
          columns.empty?
        end))
      end

      private

      def validator_needed?(model, column)
        ![model.primary_key, 'created_at', 'updated_at'].include?(column.name) &&
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
