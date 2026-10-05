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
        @runner ||= begin
          connection = ActiveRecord::Base.connection
          schema_inspector = ActiveRecordDoctor::CachingSchemaInspector.new(connection)
          ActiveRecordDoctor::Runner.new(config: config, logger: logger, schema_inspector: schema_inspector)
        end
      end

      def config
        @config ||=
          ActiveRecordDoctor.load_config_with_defaults(effective_config_path)
      end

      def effective_config_path
        if config_path.nil?
          # No explicit config_path was set, so we're trying to use defaults.
          legacy_default_path = Rails.root.join(".active_record_doctor")
          new_default_path = Rails.root.join(".active_record_doctor.rb")

          # First, if the legacy file exists we'll use it but show a warning.
          if legacy_default_path.exist?
            warn(<<~WARN.squish)
              DEPRECATION WARNING: active_record_doctor is using the default
              configuration file located in #{legacy_default_path.basename}. However,
              that default will change to #{new_default_path.basename} in the future.

              In order to avoid errors, please rename the file from
              #{legacy_default_path.basename} to #{new_default_path.basename}.
            WARN

            return legacy_default_path
          end

          # Second, if the legacy file does NOT exist, but the new one does then
          # we'll use that.
          if new_default_path.exist?
            return new_default_path
          end

          # Otherwise, there's no configuration file in use.
          nil
        else
          # If an explicit configuration file was set then we use it as is.
          config_path
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
