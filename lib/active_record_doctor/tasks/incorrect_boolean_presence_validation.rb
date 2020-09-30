require "active_record_doctor/tasks/base"

module ActiveRecordDoctor
  module Tasks
    class IncorrectBooleanPresenceValidation < Base
      @description = 'Detect boolean columns with presence/absence instead of includes/excludes validators'

      def run
        eager_load!

        success(hash_from_pairs(models.reject do |model|
          model.table_name.nil? ||
          model.table_name == 'schema_migrations' ||
          !table_exists?(model.table_name)
        end.map do |model|
          [
            model.name,
            connection.columns(model.table_name).select do |column|
              column.type == :boolean &&
                has_presence_validator?(model, column)
            end.map(&:name)
          ]
        end.reject do |model_name, columns|
          columns.empty?
        end))
      end

      private

      def has_presence_validator?(model, column)
        model.validators.any? do |validator|
          validator.kind == :presence && validator.attributes.include?(column.name.to_sym)
        end
      end
    end
  end
end
