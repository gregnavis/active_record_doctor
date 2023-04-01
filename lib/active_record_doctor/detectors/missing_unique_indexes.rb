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

      # rubocop:disable Layout/LineLength
      def message(model:, table:, columns:, problem:)
        case problem
        when :validations
          "add a unique index on #{table}(#{columns.join(', ')}) - validating uniqueness in the model without an index can lead to duplicates"
        when :has_ones
          "add a unique index on #{table}(#{columns.join(', ')}) - using `has_one` in the #{model.name} model without an index can lead to duplicates"
        end
      end
      # rubocop:enable Layout/LineLength

      def detect
        validations_without_indexes
        has_ones_without_indexes
      end

      def validations_without_indexes
        each_model(except: config(:ignore_models), existing_tables_only: true) do |model|
          model.validators.each do |validator|
            scope = Array(validator.options.fetch(:scope, []))

            next unless validator.is_a?(ActiveRecord::Validations::UniquenessValidator)
            next unless supported_validator?(validator)

            validator.attributes.each do |attribute|
              columns = resolve_attributes(model, scope + [attribute])

              next if unique_index?(model.table_name, columns)
              next if ignore_columns.include?("#{model.name}(#{columns.join(',')})")

              problem!(model: model, table: model.table_name, columns: columns, problem: :validations)
            end
          end
        end
      end

      def has_ones_without_indexes # rubocop:disable Naming/PredicateName
        each_model do |model|
          each_association(model, type: :has_one, has_scope: false, through: false) do |has_one|
            next if config(:ignore_models).include?(has_one.klass.name)

            columns =
              if has_one.options[:as]
                [has_one.type.to_s, has_one.foreign_key.to_s]
              else
                [has_one.foreign_key.to_s]
              end
            next if ignore_columns.include?("#{model.name}(#{columns.join(',')})")

            table_name = has_one.klass.table_name
            next if unique_index?(table_name, columns)

            problem!(model: model, table: table_name, columns: columns, problem: :has_ones)
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

      def unique_index?(table_name, columns, scope = nil)
        columns = (Array(scope) + columns).map(&:to_s)
        indexes(table_name).any? do |index|
          index.unique &&
            index.where.nil? &&
            (Array(index.columns) - columns).empty?
        end
      end

      def ignore_columns
        @ignore_columns ||= config(:ignore_columns).map do |column|
          column.gsub(" ", "")
        end
      end
    end
  end
end
