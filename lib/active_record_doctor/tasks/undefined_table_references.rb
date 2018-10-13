require "active_record_doctor/tasks/base"

module ActiveRecordDoctor
  module Tasks
    class UndefinedTableReferences < Base
      def run
        eager_load!

        models = models.select do |model|
          model.table_name.present? &&
            !model.connection.tables.include?(model.table_name)
        end

        [models, models.blank?]
      end
    end
  end
end
