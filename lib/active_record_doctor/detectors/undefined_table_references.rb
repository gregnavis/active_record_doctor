# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    # Find models referencing non-existent database tables or views.
    class UndefinedTableReferences < Base
      @description = "Detect models referencing undefined tables or views"

      def run
        eager_load!

        # If we can't list views due to old Rails version or unsupported
        # database then existing_views is nil. We inform the caller we haven't
        # consulted views so that it can display an appropriate warning.
        existing_views = views

        offending_models = models.select do |model|
          model.table_name.present? &&
            !tables.include?(model.table_name) &&
            (
              existing_views.nil? ||
                !existing_views.include?(model.table_name)
            )
        end.map do |model|
          [model.name, model.table_name]
        end

        problems(offending_models, views_checked: !existing_views.nil?)
      end
    end
  end
end
