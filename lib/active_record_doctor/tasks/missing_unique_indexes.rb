require "active_record_doctor/tasks/base"

module ActiveRecordDoctor
  module Tasks
    class MissingUniqueIndexes < Base
      def run
        eager_load!

        success(hash_from_pairs(models.reject do |model|
          model.table_name.nil?
        end.map do |model|
          [
            model.table_name,
            model.validators.select do |validator|
              table_name = model.table_name
              attributes = validator.attributes
              scope = validator.options.fetch(:scope, [])

              validator.is_a?(ActiveRecord::Validations::UniquenessValidator) &&
                supported_validator?(validator) &&
                !unique_index?(table_name, attributes, scope)
            end.map do |validator|
              scope = Array(validator.options.fetch(:scope, []))
              attributes = validator.attributes
              (scope + attributes).map(&:to_s)
            end
          ]
        end.reject do |_table_name, indexes|
          indexes.empty?
        end))
      end

      private

      def supported_validator?(validator)
        validator.options[:if].nil? &&
          validator.options[:unless].nil? &&
          validator.options[:conditions].nil? &&
          validator.options[:case_sensitive]
      end

      def unique_index?(table_name, columns, scope)
        columns = (Array(scope) + columns).map(&:to_s)

        indexes(table_name).any? do |index|
          index.columns == columns && index.unique
        end
      end
    end
  end
end
