# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    class MissingNonNullConstraint < Base # :nodoc:
      @description = "detect columns whose presence is always validated but isn't enforced via a non-NULL constraint"
      @config = {
        ignore_tables: {
          description: "tables whose columns should not be checked",
          global: true
        },
        ignore_columns: {
          description: "columns, written as table.column, that should not be checked"
        }
      }

      private

      def message(column:, table:)
        "add `NOT NULL` to #{table}.#{column} - models validates its presence but it's not non-NULL in the database"
      end

      def detect
        table_models = models.select(&:table_exists?).group_by(&:table_name)

        table_models.each do |table, models|
          next if ignored?(table, config(:ignore_tables))

          concrete_models = models.reject do |model|
            model.abstract_class? || sti_base_model?(model)
          end

          connection.columns(table).each do |column|
            next if ignored?("#{table}.#{column.name}", config(:ignore_columns))
            next if !column.null
            next if !concrete_models.all? { |model| non_null_needed?(model, column) }
            next if sti_column?(models, column.name)
            next if not_null_check_constraint_exists?(table, column)

            problem!(column: column.name, table: table)
          end
        end
      end

      def sti_base_model?(model)
        model.base_class == model &&
          model.columns_hash.include?(model.inheritance_column.to_s)
      end

      def non_null_needed?(model, column)
        belongs_to = model.reflect_on_all_associations(:belongs_to).find do |reflection|
          reflection.foreign_key == column.name ||
            (reflection.polymorphic? && reflection.foreign_type == column.name)
        end

        required_presence_validators(model).any? do |validator|
          attributes = validator.attributes

          attributes.include?(column.name.to_sym) ||
            (belongs_to && attributes.include?(belongs_to.name.to_sym))
        end
      end

      def required_presence_validators(model)
        model.validators.select do |validator|
          validator.is_a?(ActiveRecord::Validations::PresenceValidator) &&
            !validator.options[:allow_nil] &&
            !validator.options[:if] &&
            !validator.options[:unless]
        end
      end

      def sti_column?(models, column_name)
        models.any? { |model| model.inheritance_column == column_name }
      end
    end
  end
end
