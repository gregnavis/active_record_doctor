# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    class IncorrectDependentOption < Base # :nodoc:
      @description = "detect associations with incorrect dependent options"
      @config = {
        ignore_databases: {
          description: "databases whose models should not be checked",
          global: true
        },
        ignore_models: {
          description: "models whose associations should not be checked",
          global: true
        },
        ignore_associations: {
          description: "associations, written as Model.association, that should not be checked"
        }
      }

      private

      def message(model:, association:, problem:, associated_models_type: nil,
                  table_name: nil, column_name: nil, associated_models: [])
        associated_models.sort!

        models_part =
          if associated_models.length == 1
            "model #{associated_models[0]} has"
          else
            "models #{associated_models.join(', ')} have"
          end

        if associated_models_type
          models_part = "#{associated_models_type} #{models_part}"
        end

        # rubocop:disable Layout/LineLength
        case problem
        when :invalid_through
          "ensure #{model}.#{association} is configured correctly - #{associated_models[0]}.#{association} may be undefined"
        when :destroy_async
          "don't use `dependent: :destroy_async` on #{model}.#{association} or remove the foreign key from #{table_name}.#{column_name} - " \
          "associated models will be deleted in the same transaction along with #{model}"
        when :suggest_destroy
          "use `dependent: :destroy` or similar on #{model}.#{association} - associated #{models_part} callbacks that are currently skipped"
        when :suggest_delete
          "use `dependent: :delete` or similar on #{model}.#{association} - associated #{models_part} no callbacks and can be deleted without loading"
        when :suggest_delete_all
          "use `dependent: :delete_all` or similar on #{model}.#{association} - associated #{models_part} no callbacks and can be deleted in bulk"
        end
        # rubocop:enable Layout/LineLength
      end

      def detect
        each_model(except: config(:ignore_models), ignore_databases: config(:ignore_databases), existing_tables_only: true) do |model|
          each_association(model, except: config(:ignore_associations)) do |association|
            # A properly configured :through association will have a non-nil
            # source_reflection. If it's nil then it indicates the :through
            # model lacks the next leg in the :through relationship. For
            # instance, if user has many comments through posts then a nil
            # source_reflection means that Post doesn't define +has_many :comments+.
            if through?(association) && association.source_reflection.nil?
              log("through association with nil source_reflection")

              through_association = model.reflect_on_association(association.options.fetch(:through))
              association_on_join_model = through_association.klass.reflect_on_association(association.name)

              # We report a problem only if the +has_many+ association mentioned
              # above is actually missing. We let the detector continue in other
              # cases, risking an exception, as the absence of source_reflection
              # must be caused by something else in those cases. Each further
              # exception will be handled on a case-by-case basis.
              if association_on_join_model.nil?
                problem!(
                  model: model.name,
                  association: association.name,
                  problem: :invalid_through,
                  associated_models: [through_association.klass.name],
                  associated_models_type: "join"
                )
                next
              end
            end

            associated_models, associated_models_type =
              if association.polymorphic?
                [models_having_association_with_options(as: association.name), nil]
              elsif through?(association)
                [[association.source_reflection.active_record], "join"]
              else
                [[association.klass], nil]
              end

            deletable_models, destroyable_models = associated_models.partition { |klass| deletable?(klass) }

            case association.options[:dependent]
            when :destroy_async
              foreign_key = foreign_key(association.klass.table_name, model.table_name)
              if foreign_key
                problem!(
                  model: model.name,
                  association: association.name,
                  table_name: foreign_key.from_table,
                  column_name: foreign_key.column,
                  problem: :destroy_async
                )
              end
            when :destroy
              if destroyable_models.empty? && deletable_models.present?
                suggestion =
                  case association.macro
                  when :has_many then :suggest_delete_all
                  when :has_one, :belongs_to then :suggest_delete
                  else raise("unsupported association type #{association.macro}")
                  end

                problem!(
                  model: model.name,
                  association: association.name,
                  problem: suggestion,
                  associated_models: deletable_models.map(&:name),
                  associated_models_type: associated_models_type
                )
              end
            when :delete, :delete_all
              if destroyable_models.present?
                problem!(
                  model: model.name,
                  association: association.name,
                  problem: :suggest_destroy,
                  associated_models: destroyable_models.map(&:name),
                  associated_models_type: associated_models_type
                )
              end
            end
          end
        end
      end

      def models_having_association_with_options(as:)
        models.select do |model|
          associations = model.reflect_on_all_associations(:has_one) +
                         model.reflect_on_all_associations(:has_many)

          associations.any? do |association|
            association.options[:as] == as
          end
        end
      end

      def deletable?(model)
        !defines_destroy_callbacks?(model) &&
          dependent_models(model).all? do |dependent_model|
            foreign_key = foreign_key(dependent_model.table_name, model.table_name)

            foreign_key.nil? ||
              foreign_key.on_delete == :nullify || (
                foreign_key.on_delete == :cascade && deletable?(dependent_model)
              )
          end
      end

      def through?(reflection)
        reflection.is_a?(ActiveRecord::Reflection::ThroughReflection)
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

      def dependent_models(model)
        reflections = model.reflect_on_all_associations(:has_many) +
                      model.reflect_on_all_associations(:has_one)
        reflections.map(&:klass)
      end

      def foreign_key(from_table, to_table)
        connection.foreign_keys(from_table).find do |foreign_key|
          foreign_key.to_table == to_table
        end
      end
    end
  end
end
