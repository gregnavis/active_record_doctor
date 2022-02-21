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
        table_models = models.group_by(&:table_name)
        table_models.delete_if { |_table, models| !models.first.table_exists? }

        table_models.each do |table, models|
          next if config(:ignore_tables).include?(table)

          concrete_models = models.reject do |model|
            model.abstract_class? || sti_base_model?(model)
          end

          connection.columns(table).each do |column|
            next if config(:ignore_columns).include?("#{table}.#{column.name}")
            next if !column.null
            next if !concrete_models.all? { |model| non_null_needed?(model, column) }
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

      def not_null_check_constraint_exists?(table, column)
        check_constraints(table).any? do |definition|
          definition =~ /\A#{column.name} IS NOT NULL\z/i ||
            definition =~ /\A#{connection.quote_column_name(column.name)} IS NOT NULL\z/i
        end
      end
    end
  end
end
