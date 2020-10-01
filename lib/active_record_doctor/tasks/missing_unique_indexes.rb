require "active_record_doctor/tasks/base"

module ActiveRecordDoctor
  module Tasks
    class MissingUniqueIndexes < Base
      @description = 'Detect columns covered by a uniqueness validator without a unique index'

      def run
        eager_load!

        success(hash_from_pairs(models.reject do |model|
          model.table_name.nil?
        end.map do |model|
          [
            model.table_name,
            model.validators.select do |validator|
              table_name = model.table_name
              scope = validator.options.fetch(:scope, [])

              validator.is_a?(ActiveRecord::Validations::UniquenessValidator) &&
                supported_validator?(validator) &&
                !unique_index?(table_name, validator.attributes, scope)
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

          # In Rails 6, default option values are no longer explicitly set on
          # options so if the key is absent we must fetch the default value
          # ourselves. case_sensitive is the default in 4.2+ so it's safe to
          # put true literally.
          validator.options.fetch(:case_sensitive, true)
      end

      def unique_index?(table_name, columns, scope)
        columns = (Array(scope) + columns).map(&:to_s)

        indexes(table_name).any? do |index|
          index.columns.to_set == columns.to_set && index.unique
        end
      end
    end
  end
end
