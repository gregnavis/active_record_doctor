# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    class UndefinedTableReferences < Base # :nodoc:
      @description = "detect models referencing undefined tables or views"
      @config = {
        ignore_models: {
          description: "models whose underlying tables should not be checked for existence",
          global: true
        }
      }

      private

      def message(model:, table:)
        "#{model} references a non-existent table or view named #{table}"
      end

      def detect
        models(except: config(:ignore_models)).each do |model|
          next if model.table_name.nil?
          next if tables.include?(model.table_name)
          next if tables_and_views.include?(model.table_name)

          problem!(model: model.name, table: model.table_name)
        end
      end
    end
  end
end
