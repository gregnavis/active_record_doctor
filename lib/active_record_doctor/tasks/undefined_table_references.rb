require "active_record_doctor/tasks/base"

module ActiveRecordDoctor
  module Tasks
    class UndefinedTableReferences < Base
      def run
        Rails.application.eager_load!

        models = ActiveRecord::Base.descendants.select do |model|
          model.table_name.present? &&
            !model.connection.tables.include?(model.table_name)
        end

        [models, models.blank?]
      end
    end
  end
end
