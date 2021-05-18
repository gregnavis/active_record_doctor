# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    # Find has_many/has_one associations with dependent options not taking the
    # related model's callbacks into account.
    class IncorrectDependentOption < Base
      # rubocop:disable Layout/LineLength
      @description = "Detect associations that should use a different dependent option based on callbacks on the related model"
      # rubocop:enable Layout/LineLength

      def run
        eager_load!

        problems(hash_from_pairs(models.reject do |model|
          model.table_name.nil?
        end.map do |model|
          [
            model.name,
            associations_with_incorrect_dependent_options(model)
          ]
        end.reject do |_model_name, associations|
          associations.empty?
        end))
      end

      private

      def associations_with_incorrect_dependent_options(model)
        reflections = model.reflect_on_all_associations(:has_many) + model.reflect_on_all_associations(:has_one)
        reflections.map do |reflection|
          if callback_action(reflection) == :invoke && !defines_destroy_callbacks?(reflection.klass)
            suggestion =
              case reflection.macro
              when :has_many then :suggest_delete_all
              when :has_one then :suggest_delete
              else raise("unsupported association type #{reflection.macro}")
              end

            [reflection.name, suggestion]
          elsif callback_action(reflection) == :skip && defines_destroy_callbacks?(reflection.klass)
            [reflection.name, :suggest_destroy]
          end
        end.compact
      end

      def callback_action(reflection)
        case reflection.options[:dependent]
        when :delete_all then :skip
        when :destroy then :invoke
        end
      end

      def defines_destroy_callbacks?(model)
        # Destroying an associated model involves loading it first hence
        # initialize and find are present. If they are defined on the model
        # being deleted then theoretically we can't use :delete_all. It's a bit
        # of an edge case as they usually are either absent or have no side
        # effects but we're being pedantic -- they could be used for audit
        # trial, for instance, and we don't want to skip that.
        model._initialize_callbacks.present? ||
          model._find_callbacks.present? ||
          model._destroy_callbacks.present? ||
          model._commit_callbacks.present? ||
          model._rollback_callbacks.present?
      end
    end
  end
end
