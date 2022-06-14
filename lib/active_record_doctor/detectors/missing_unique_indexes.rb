# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    class MissingUniqueIndexes < Base # :nodoc:
      @description = "detect uniqueness validators not backed by a database constraint"
      @config = {
        ignore_models: {
          description: "models whose uniqueness validators should not be checked",
          global: true
        },
        ignore_columns: {
          description: "specific validators, written as Model(column1, column2, ...), that should not be checked"
        }
      }

      private

      def message(table:, columns:)
        # rubocop:disable Layout/LineLength
        "add a unique index on #{table}(#{columns.join(', ')}) - validating uniqueness in the model without an index can lead to duplicates"
        # rubocop:enable Layout/LineLength
      end

      def detect
        ignore_columns = config(:ignore_columns).map do |column|
          column.gsub(" ", "")
        end

        models(except: config(:ignore_models)).each do |model|
          next unless model.table_exists?

          model.validators.each do |validator|
            scope = Array(validator.options.fetch(:scope, []))

            next unless validator.is_a?(ActiveRecord::Validations::UniquenessValidator)
            next unless supported_validator?(validator)

            validator.attributes.each do |attribute|
              columns = resolve_attributes(model, scope + [attribute])

              next if unique_index?(model.table_name, columns)
              next if ignore_columns.include?("#{model.name}(#{columns.join(',')})")

              problem!(table: model.table_name, columns: columns)
            end
          end
        end
      end

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

      def resolve_attributes(model, attributes)
        attributes.flat_map do |attribute|
          reflection = model.reflect_on_association(attribute)

          if reflection.nil?
            attribute
          elsif reflection.polymorphic?
            [reflection.foreign_type, reflection.foreign_key]
          else
            reflection.foreign_key
          end
        end.map(&:to_s)
      end

      def unique_index?(table_name, columns)
        indexes(table_name).any? do |index|
          index.unique &&
            index.where.nil? &&
            (Array(index.columns) - columns).empty?
        end
      end
    end
  end
end
