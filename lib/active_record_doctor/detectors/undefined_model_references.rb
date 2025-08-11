# frozen_string_literal: true

require 'active_record_doctor/detectors/base'

module ActiveRecordDoctor
  module Detectors
    class UndefinedModelReferences < Base # :nodoc:
      @description = 'detect tables not referenced by any model'
      @config = {
        ignore_tables: {
          description: 'tables whose corresponding models should not be checked for existence',
          global: true
        }
      }

      private

      def message(table:, **)
        "The #{table} table is not referenced by a Rails model. If you are in the process of migrating it away, temporarily ignore it " \
          'by adding it to the `ignore_tables` configuration and then remove it after the ruby code no longer uses it. ' \
          'Remember, do not delete the table until your deployed application code no longer uses it.'
      end

      def detect
        each_table(except: config(:ignore_tables)) do |table|
          matching_model = ActiveRecord::Base.descendants.find do |model|
            model.table_name == table
          end

          problem!(table:) if matching_model.nil?
        end
      end
    end
  end
end