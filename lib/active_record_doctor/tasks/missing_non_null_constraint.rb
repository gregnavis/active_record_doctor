require "active_record_doctor/tasks/base"

module ActiveRecordDoctor
  module Tasks
    class MissingNonNullConstraint < Base
      def run
        eager_load!

        success(hash_from_pairs(models.reject do |model|
          model.table_name.nil? || model.table_name == 'schema_migrations'
        end.map do |model|
          [
            model.table_name,
            connection.columns(model.table_name).select do |column|
              validator_needed?(model, column) &&
                has_mandatory_presence_validator?(model, column) &&
                column.null
            end.map(&:name)
          ]
        end.reject do |model_name, columns|
          columns.empty?
        end))
      end

      private

      def validator_needed?(model, column)
        ![model.primary_key, 'created_at', 'updated_at'].include?(column.name)
      end

      def has_mandatory_presence_validator?(model, column)
        model.validators.any? do |validator|
          validator.is_a?(ActiveRecord::Validations::PresenceValidator) &&
            validator.attributes.include?(column.name.to_sym) &&
            !validator.options[:allow_nil] &&
            !validator.options[:if] &&
            !validator.options[:unless]
        end
      end
    end
  end
end
