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
        each_model(except: config(:ignore_models), abstract: false) do |model|
          next if connection.data_source_exists?(model.table_name)

          problem!(model: model.name, table: model.table_name)
        end
      end
    end
  end
end
