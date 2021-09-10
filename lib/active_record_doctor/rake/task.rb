# frozen_string_literal: true

require "rake/tasklib"

module ActiveRecordDoctor
  module Rake
    # A Rake task for calling active_record_doctor detectors.
    class Task < ::Rake::TaskLib
      attr_accessor :deps, :config_path, :default_init

      def initialize
        super

        @deps = []
        @config_path = nil
        @default_init = nil

        yield(self)

        define
      end

      def define
        namespace :active_record_doctor do
          ActiveRecordDoctor.detectors.each do |name, detector|
            desc detector.description
            task name => deps do
              runner.run(detector) or exit(1)
            end
          end
        end

        desc "Run all active_record_doctor detectors"
        task active_record_doctor: deps do
          success = true

          # We can't use #all? because of its short-circuit behavior - it stops
          # iteration and returns false upon the first falsey value. This
          # prevents other detectors from running if there's a failure.
          ActiveRecordDoctor.detectors.each do |_name, detector|
            unless runner.run(detector)
              success = false
            end
          end

          exit(1) unless success
        end
      end

      private

      def runner
        @runner ||= ActiveRecordDoctor.handle_exception do
          ActiveRecordDoctor::Runner.new(config)
        end
      end

      def config
        if config_path && File.exist?(config_path)
          config = ActiveRecordDoctor.load_config(config_path)
          config.init ||= default_init
        else
          default_config
        end
      end

      def default_config
        ActiveRecordDoctor::Config.new(default_init, {})
      end
    end
  end
end
