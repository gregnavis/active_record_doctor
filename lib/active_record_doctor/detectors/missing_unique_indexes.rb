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
        },
        ignore_join_tables: {
          description: "join tables that should not be checked for existence of unique indexes"
        }
      }

      def initialize(**)
        super
        @reported_join_tables = []
      end

      private

      # rubocop:disable Layout/LineLength
      def message(model:, table:, columns:, problem:)
        case problem
        when :validations
          "add a unique index on #{table}(#{columns.join(', ')}) - validating uniqueness in #{model.name} without an index can lead to duplicates"
        when :case_insensitive_validations
          "add a unique expression index on #{table}(#{columns.join(', ')}) - validating case-insensitive uniqueness in #{model.name} " \
          "without an expression index can lead to duplicates (a regular unique index is not enough)"
        when :has_ones
          "add a unique index on #{table}(#{columns.join(', ')}) - using `has_one` in #{model.name} without an index can lead to duplicates"
        when :has_and_belongs_to_many
          "add a unique index on #{table}(#{columns.join(', ')}) - using `has_and_belongs_to_many` in #{model.name} without an index can lead to duplicates"
        end
      end
      # rubocop:enable Layout/LineLength

      def detect
        validations_without_indexes
        has_ones_without_indexes
        has_and_belongs_to_many_without_indexes
      end

      def validations_without_indexes
        each_model(except: config(:ignore_models), existing_tables_only: true) do |model|
          # Skip inherited validators from STI to prevent them
          # from being reported multiple times on subclasses.
          validators = model.validators - model.superclass.validators
          validators.each do |validator|
            scope = Array(validator.options.fetch(:scope, []))

            next unless validator.is_a?(ActiveRecord::Validations::UniquenessValidator)
            next if conditional_validator?(validator)

            # In Rails 6, default option values are no longer explicitly set on
            # options so if the key is absent we must fetch the default value
            # ourselves. case_sensitive is the default in 4.2+ so it's safe to
            # put true literally.
            case_sensitive = validator.options.fetch(:case_sensitive, true)

            # ActiveRecord < 5.0 does not support expression indexes,
            # so this will always be a false positive.
            next if !case_sensitive && Utils.expression_indexes_unsupported?

            validator.attributes.each do |attribute|
              columns = resolve_attributes(model, scope + [attribute])

              next if ignore_columns.include?("#{model.name}(#{columns.join(',')})")

              columns[-1] = "lower(#{columns[-1]})" unless case_sensitive

              next if unique_index?(model.table_name, columns)

              if case_sensitive
                problem!(model: model, table: model.table_name, columns: columns, problem: :validations)
              else
                problem!(
                  model: model,
                  table: model.table_name,
                  columns: columns,
                  problem: :case_insensitive_validations
                )
              end
            end
          end
        end
      end

      def has_ones_without_indexes # rubocop:disable Naming/PredicateName
        each_model do |model|
          each_association(model, type: :has_one, has_scope: false, through: false) do |has_one|
            next if ignored?(has_one.klass.name, config(:ignore_models))

            columns =
              if has_one.options[:as]
                [has_one.type.to_s, has_one.foreign_key.to_s]
              else
                [has_one.foreign_key.to_s]
              end
            next if ignored?("#{has_one.klass.name}(#{columns.join(',')})", ignore_columns)

            table_name = has_one.klass.table_name
            next if unique_index?(table_name, columns)
            next if Array(connection.primary_key(table_name)) == columns

            problem!(model: model, table: table_name, columns: columns, problem: :has_ones)
          end
        end
      end

      def conditional_validator?(validator)
        (validator.options.keys & [:if, :unless, :conditions]).present?
      end

      def has_and_belongs_to_many_without_indexes # rubocop:disable Naming/PredicateName
        each_model do |model|
          each_association(model, type: :has_and_belongs_to_many, has_scope: false) do |association|
            join_table = association.join_table
            next if @reported_join_tables.include?(join_table) || config(:ignore_join_tables).include?(join_table)

            columns = [association.foreign_key, association.association_foreign_key]
            next if unique_index?(join_table, columns)

            @reported_join_tables << join_table
            problem!(model: model, table: join_table, columns: columns, problem: :has_and_belongs_to_many)
          end
        end
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
          index_columns =
            # For expression indexes, Active Record returns columns as string.
            if index.columns.is_a?(String)
              extract_index_columns(index.columns)
            else
              index.columns
            end

          index.unique &&
            index.where.nil? &&
            (index_columns - columns).empty?
        end
      end

      def ignore_columns
        @ignore_columns ||= config(:ignore_columns).map do |column|
          if column.is_a?(String)
            column.gsub(" ", "")
          else
            column
          end
        end
      end

      def extract_index_columns(columns)
        columns
          .split(",")
          .map(&:strip)
          .map do |column|
            column.gsub(/lower\(/i, "lower(")
                  .gsub(/\((\w+)\)::\w+/, '\1') # (email)::string
                  .gsub(/([`'"])(\w+)\1/, '\2') # quoted identifiers
                  .gsub(/\A\((.+)\)\z/, '\1')   # remove surrounding braces from MySQL
          end
      end
    end
  end
end
