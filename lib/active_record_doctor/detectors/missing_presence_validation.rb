# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    class MissingPresenceValidation < Base # :nodoc:
      @description = "detect non-NULL columns without a corresponding presence validator"
      @config = {
        ignore_models: {
          description: "models whose underlying tables' columns should not be checked",
          global: true
        },
        ignore_attributes: {
          description: "specific attributes, written as Model.attribute, that should not be checked"
        },
        ignore_columns_with_default: {
          description: "ignore columns with default values, should be provided as boolean"
        }
      }

      private

      def message(type:, column_or_association:, model:)
        case type
        when :missing_validator
          "add a `presence` validator to #{model}.#{column_or_association} - it's NOT NULL but lacks a validator"
        when :optional_association
          "add `optional: false` to #{model}.#{column_or_association} - the foreign key #{column_or_association}_id is NOT NULL" # rubocop:disable Layout/LineLength
        when :optional_polymorphic_association
          "add `optional: false` to #{model}.#{column_or_association} - the foreign key #{column_or_association}_id or type #{column_or_association}_type are NOT NULL" # rubocop:disable Layout/LineLength
        end
      end

      def detect
        each_model(except: config(:ignore_models), existing_tables_only: true) do |model|
          # List all columns and then remove those that don't need or don't have
          # a missing validator.
          problematic_columns = connection.columns(model.table_name)
          problematic_columns.reject! do |column|
            # The primary key, timestamps, and counter caches are special
            # columns that are automatically managed by Rails and don't need
            # an explicit presence validator.
            column.name == model.primary_key ||
              ["created_at", "updated_at", "created_on", "updated_on"].include?(column.name) ||
              counter_cache_column?(model, column) ||

              # NULL-able columns don't need a presence validator as they can be
              # set to NULL after all. A check constraint (column IS NOT NULL)
              # is an alternative approach and the absence of such constraint is
              # tested below.
              (column.null && !not_null_check_constraint_exists?(model.table_name, column)) ||

              # If requested, columns with a default value don't need presence
              # validation as they'd have the default value substituted automatically.
              (config(:ignore_columns_with_default) && (column.default || column.default_function)) ||

              # Explicitly ignored columns should be skipped.
              config(:ignore_attributes).include?("#{model.name}.#{column.name}")
          end

          # At this point the only columns that are left are those that DO
          # need presence validation in the model. Let's iterate over all
          # validators to see which columns are actually validated, but before
          # we do that let's define a map for quickly translating column names
          # to association names.
          column_name_to_association_name = {}
          model.reflect_on_all_associations.each do |reflection|
            column_name_to_association_name[reflection.foreign_key] = reflection.name
            if reflection.polymorphic?
              column_name_to_association_name[reflection.foreign_type] = reflection.name
            end
          end

          # We're now ready to iterate over the validators and remove columns
          # that are validated directly or via an association name.
          model.validators.each do |validator|
            problematic_columns.reject! do |column|
              # Translate a foreign key or type to the association name.
              attribute = column_name_to_association_name[column.name] || column.name.to_sym

              case validator

              # A regular presence validator is enough if the column name is
              # listed among the attributes it's validating.
              when ActiveRecord::Validations::PresenceValidator
                validator.attributes.include?(attribute)

              # An inclusion validator ensures the column is not nil if it covers
              # the column and nil is NOT one of the values it allows.
              when ActiveModel::Validations::InclusionValidator
                validator_items = inclusion_or_exclusion_validator_items(validator)
                validator.attributes.include?(attribute) &&
                  (validator_items.is_a?(Proc) || validator_items.exclude?(nil))

              # An exclusion validator ensures the column is not nil if it covers
              # the column and excludes nil as an allowed value explicitly.
              when ActiveModel::Validations::ExclusionValidator
                validator_items = inclusion_or_exclusion_validator_items(validator)
                validator.attributes.include?(attribute) &&
                  (validator_items.is_a?(Proc) || validator_items.include?(nil))

              end
            end
          end

          # Associations need to be checked whether they're marked optional
          # while the underlying foreign key or type columns are marked NOT NULL.
          problematic_associations = []
          problematic_polymorphic_associations = []

          model.reflect_on_all_associations.each do |reflection|
            foreign_key_column = problematic_columns.find { |column| column.name == reflection.foreign_key }
            if reflection.polymorphic?
              # If the foreign key and type are not one of the columns that lack
              # a validator then it means the association added a validator and
              # is configured correctly.
              foreign_type_column = problematic_columns.find { |column| column.name == reflection.foreign_type }
              next if foreign_key_column.nil? && foreign_type_column.nil?

              # Otherwise, don't report errors about missing validators on the
              # foreign key or type, but instead ...
              problematic_columns.delete(foreign_key_column)
              problematic_columns.delete(foreign_type_column)

              # ... report an error about an incorrectly configured polymorphic
              # association.
              problematic_polymorphic_associations << reflection.name
            else
              # If the foreign key is not one of the columns that lack a
              # validator then it means the association added a validator and is
              # configured correctly.
              next if foreign_key_column.nil?

              # Otherwise, don't report an error about a missing validator on
              # the foreign key, but instead ...
              problematic_columns.delete(foreign_key_column)

              # ... report an error about an incorrectly configured association.
              problematic_associations << reflection.name
            end
          end

          # Finally, regular and polymorphic associations that are explicitly
          # ignored should be removed from the output. It's NOT enough to skip
          # processing them in the loop above because their underlying foreign
          # key and type columns must be removed from output, too.
          problematic_associations.reject! do |name|
            config(:ignore_attributes).include?("#{model.name}.#{name}")
          end
          problematic_polymorphic_associations.reject! do |name|
            config(:ignore_attributes).include?("#{model.name}.#{name}")
          end

          # Job is done and all accumulated errors can be reported.
          problematic_polymorphic_associations.each do |name|
            problem!(type: :optional_polymorphic_association, column_or_association: name, model: model.name)
          end
          problematic_associations.each do |name|
            problem!(type: :optional_association, column_or_association: name, model: model.name)
          end
          problematic_columns.each do |column|
            problem!(type: :missing_validator, column_or_association: column.name, model: model.name)
          end
        end
      end

      # Normalizes the list of values passed to an inclusion or exclusion validator.
      def inclusion_or_exclusion_validator_items(validator)
        validator.options[:in] || validator.options[:within] || []
      end

      # Determines whether the given column is used as a counter cache column by
      # a has_many association on the model.
      def counter_cache_column?(model, column)
        model.reflect_on_all_associations(:has_many).any? do |reflection|
          reflection.has_cached_counter? && reflection.counter_cache_column == column.name
        end
      end
    end
  end
end
