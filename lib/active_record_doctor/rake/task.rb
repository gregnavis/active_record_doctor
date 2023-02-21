# frozen_string_literal: true

require "rake/tasklib"

module ActiveRecordDoctor
  module Rake
    # A Rake task for calling active_record_doctor detectors.
    #
    # The three supported attributes are:
    #
    #   - deps - project-specific Rake dependencies, e.g. :environment in Rails.
    #   - config_path - active_record_doctor configuration file path.
    #   - setup - a callable (responding to #call) responsible for finishing.
    #     the setup process after deps are invoked, e.g. preloading models.
    #
    # The dependencies between Rake tasks are:
    #
    #    active_record_doctor:<detector> => active_record_doctor:setup => <deps>
    #
    # active_record_doctor:setup is where the setup callable is called.
    class Task < ::Rake::TaskLib
      attr_accessor :deps, :config_path, :setup

      def initialize
        super

        @deps = []
        @config_path = nil
        @setup = nil

        yield(self)

        define
      end

      def define
        namespace :active_record_doctor do
          task :setup => deps do
            @setup&.call
            config
          end

          ActiveRecordDoctor.detectors.each do |name, detector|
            desc detector.description
            task name => :"active_record_doctor:setup" do
              runner.run_one(name) or exit(1)
            end

            namespace name do
              desc "Show help for #{name}"
              task :help => :"active_record_doctor:setup" do
                runner.help(name)
              end
            end
          end
        end

        desc "Run all active_record_doctor detectors"
        task :active_record_doctor => :"active_record_doctor:setup" do
          runner.run_all or exit(1)
        end
      end

      private

      def runner
        @runner ||= ActiveRecordDoctor::Runner.new(config: config, logger: logger)
      end

      def config
        @config ||= begin
          path = config_path && File.exist?(config_path) ? config_path : nil
          ActiveRecordDoctor.load_config_with_defaults(path)
        end
      end

      def logger
        @logger ||=
          if ENV.include?("ACTIVE_RECORD_DOCTOR_DEBUG")
            ActiveRecordDoctor::Logger::Hierarchical.new($stderr)
          else
            ActiveRecordDoctor::Logger::Dummy.new
          end
      end
    end
  end
end
