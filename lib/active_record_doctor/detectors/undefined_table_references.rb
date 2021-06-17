# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    # Find models referencing non-existent database tables or views.
    class UndefinedTableReferences < Base
      @description = "Detect models referencing undefined tables or views"

      private

      def message(model:, table:)
        "#{model} references a non-existent table or view named #{table}"
      end

      def detect
        eager_load!

        # If we can't list views due to old Rails version or unsupported
        # database then existing_views is nil. We inform the caller we haven't
        # consulted views so that it can display an appropriate warning.
        existing_views = views
        if existing_views.nil?
          warning(<<WARNING)
WARNING: Models backed by database views are supported only in Rails 5+ OR
Rails 4.2 + PostgreSQL. It seems this is NOT your setup. Therefore, such models
will be erroneously reported below as not having their underlying tables/views.
Consider upgrading Rails or disabling this task temporarily.
WARNING
        end

        problems(models.select do |model|
          model.table_name.present? &&
            !tables.include?(model.table_name) &&
            (
              existing_views.nil? ||
                !existing_views.include?(model.table_name)
            )
        end.map do |model|
          {
            model: model.name,
            table: model.table_name
          }
        end)
      end
    end
  end
end
