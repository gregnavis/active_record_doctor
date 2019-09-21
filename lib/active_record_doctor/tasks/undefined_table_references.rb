require "active_record_doctor/tasks/base"

module ActiveRecordDoctor
  module Tasks
    class UndefinedTableReferences < Base
      def run
        eager_load!

        # If we can't list views due to old Rails version or unsupported
        # database then existing_views is nil. We inform the caller we haven't
        # consulted views so that it can display an appropriate warning.
        existing_views = views

        offending_models = models.select do |model|
          model.table_name.present? &&
            !tables.include?(model.table_name) &&
            existing_views &&
            !existing_views.include?(model.table_name)
        end.map do |model|
          [model.name, model.table_name]
        end

        [
          [
            offending_models, # Actual results
            !existing_views.nil? # true if views were checked, false otherwise
          ],
          offending_models.blank?
        ]
      end
    end
  end
end
