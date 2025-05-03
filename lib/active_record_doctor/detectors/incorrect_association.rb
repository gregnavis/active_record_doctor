# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    class IncorrectAssociation < Base # :nodoc:
      @description = "detect incorrectly configured associations"
      @config = {
        ignore_models: {
          description: "models whose associations should not be checked",
          global: true
        },
        ignore_associations: {
          description: "associations, written as Model.association, that should not be checked"
        }
      }

      private

      def message(model:, association:, reason:)
        "association #{model.name}.#{association.name} is incorrect - #{reason}"
      end

      def detect
        each_model(except: config(:ignore_models), existing_tables_only: true) do |model|
          each_association(model, except: config(:ignore_associations)) do |association|
            case association.macro
            when :belongs_to
              check_belongs_to(model, association)
            when :has_many
              check_has_many(model, association)
            when :has_one
              check_has_one(model, association)
            when :has_and_belongs_to_many
              check_has_and_belongs_to_many(model, association)
            end
          end
        end
      end

      def check_belongs_to(model, association)
        column_names = model.column_names

        if association.polymorphic?
          # Check :foreign_type option
          unless column_names.include?(association.foreign_type)
            problem!(
              model: model,
              association: association,
              reason: "there is no '#{model.table_name}.#{association.foreign_type}' column"
            )
          end
        else
          success = check_association_model(model, association)
          return unless success

          association_model = association.klass

          # Check :foreign_key option
          unless column_names.include?(association.foreign_key)
            problem!(
              model: model,
              association: association,
              reason: "there is no '#{model.table_name}.#{association.foreign_key}' column"
            )
          end

          check_primary_key(model, association)
          association_columns = association_model.column_names

          # Check :counter_cache option
          counter_cache_column = association.counter_cache_column
          if association.options[:counter_cache] && !association_columns.include?(counter_cache_column)
            problem!(
              model: model,
              association: association,
              reason: "there is no '#{association_model.table_name}.#{counter_cache_column}' counter cache column"
            )
          end

          check_touch_option(model, association)

          # Check :inverse_of option
          if incorrect_inverse_of?(association)
            problem!(
              model: model,
              association: association,
              reason: "there is no '#{association.class_name}.#{association.options[:inverse_of]}' association"
            )
          end
        end
      end

      def check_has_many(model, association)
        if association.through_reflection?
          check_source_association(model, association)
        else
          success = check_association_model(model, association)
          return unless success

          association_model = association.klass

          column_names = model.column_names
          association_columns = association_model.column_names

          # Check :foreign_key option
          # Don't do foreign_key check if inverse_of is incorrect, because Active Record
          # uses inverse_of for getting foreign key.
          if !incorrect_inverse_of?(association) && !association_columns.include?(association.foreign_key)
            problem!(
              model: model,
              association: association,
              reason: "there is no '#{association_model.table_name}.#{association.foreign_key}' column"
            )
          end

          # Check :foreign_type option
          if association.type && !association_columns.include?(association.type)
            problem!(
              model: model,
              association: association,
              reason: "there is no '#{association_model.table_name}.#{association.type}' column"
            )
          end

          check_primary_key(model, association)

          # Check :counter_cache option
          if association.options[:counter_cache] && !column_names.include?(association.counter_cache_column)
            problem!(
              model: model,
              association: association,
              reason: "there is no '#{model.table_name}.#{association.counter_cache_column}' counter cache column"
            )
          end

          # Check :inverse_of option
          if incorrect_inverse_of?(association)
            problem!(
              model: model,
              association: association,
              reason: "there is no '#{association.class_name}.#{association.options[:inverse_of]}' association"
            )
          end
        end
      end

      def check_has_one(model, association)
        if association.through_reflection?
          check_source_association(model, association)
        else
          success = check_association_model(model, association)
          return unless success

          association_model = association.klass

          association_columns = association_model.column_names

          # Check :foreign_key option
          if !incorrect_inverse_of?(association) && !association_columns.include?(association.foreign_key)
            problem!(
              model: model,
              association: association,
              reason: "there is no '#{association_model.table_name}.#{association.foreign_key}' column"
            )
          end

          # Check :foreign_type option
          if association.type && !association_columns.include?(association.type)
            problem!(
              model: model,
              association: association,
              reason: "there is no '#{association_model.table_name}.#{association.type}' column"
            )
          end

          check_primary_key(model, association)
          check_touch_option(model, association)

          # Check :inverse_of option
          if incorrect_inverse_of?(association)
            problem!(
              model: model,
              association: association,
              reason: "there is no '#{association.class_name}.#{association.options[:inverse_of]}' association"
            )
          end
        end
      end

      def check_has_and_belongs_to_many(model, association)
        success = check_association_model(model, association)
        return unless success

        join_table = association.join_table

        # Check that join table exists
        if connection.data_source_exists?(join_table)
          # Check :foreign_key and :association_foreign_key options
          [association.foreign_key, association.association_foreign_key].each do |foreign_key|
            unless column(join_table, foreign_key)
              problem!(
                model: model,
                association: association,
                reason: "there is no '#{join_table}.#{foreign_key}' column"
              )
            end
          end
        else
          problem!(
            model: model,
            association: association,
            reason: "associated '#{join_table}' table does not exist"
          )
        end
      end

      def check_association_model(model, association)
        association_model = association.klass

        if association_model.table_exists?
          true
        else
          problem!(
            model: model,
            association: association,
            reason: "associated '#{association_model.table_name}' table does not exist"
          )
          false
        end
      rescue NameError
        problem!(
          model: model,
          association: association,
          reason: "associated '#{association.class_name}' model does not exist"
        )

        false
      end

      def check_primary_key(model, association)
        # Can't use association.active_record_primary_key, because it raises
        # if model does not have a primary key.
        primary_key = association.options[:primary_key]&.to_s || model.primary_key&.to_s || "id"

        unless model.column_names.include?(primary_key)
          problem!(
            model: model,
            association: association,
            reason: "there is no '#{model.table_name}.#{primary_key}' column"
          )
        end
      end

      def check_touch_option(model, association)
        return unless (touch = association.options[:touch])

        association_model = association.klass
        columns = association_model.column_names

        unless columns.include?("updated_at") || columns.include?("updated_on")
          problem!(
            model: model,
            association: association,
            reason: "there is no '#{association_model.table_name}.updated_at' touch column"
          )
        end

        if touch.is_a?(Symbol) && !columns.include?(touch.to_s)
          problem!(
            model: model,
            association: association,
            reason: "there is no '#{association_model.table_name}.#{touch}' touch column"
          )
        end
      end

      def check_source_association(model, association)
        if association.through_reflection
          unless association.source_reflection
            target_model = association.through_reflection.klass.name
            problem!(
              model: model,
              association: association,
              reason: "there is no '#{association.name}' association on '#{target_model}' model"
            )
          end
        else
          problem!(
            model: model,
            association: association,
            reason: "there is no '#{model.name}.#{association.options[:through]}' association"
          )
        end
      end

      def incorrect_inverse_of?(association)
        association.options[:inverse_of] && association.inverse_of.nil?
      end
    end
  end
end
