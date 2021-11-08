# frozen_string_literal: true

module ActiveRecordDoctor # :nodoc:
  def self.handle_exception
    yield
  rescue ActiveRecordDoctor::Error => e
    $stderr.puts(e.user_message)
    exit(1)
  end

  # Generic active_record_doctor exception class.
  class Error < RuntimeError
    attr_accessor :config_path

    def self.[](*args)
      new(*args)
    end

    def details
      nil
    end

    def user_message
      result =
        <<-MESSAGE
active_record_doctor aborted due to the following error:
#{message}

Configuration file:
#{config_path_or_message}
        MESSAGE

      if details
        result << (
          <<-MESSAGE

Additional information:
#{details}
          MESSAGE
        )
      end

      result
    end

    private

    def config_path_or_message
      @config_path || "no configuration file in use (using default settings)"
    end

    def hyphenated_list(items)
      items.map { |item| "  - #{item}" }.join("\n")
    end
  end

  class Error
    # We don't need extra documentation for error classes because of their
    # extensive error messages.
    # rubocop:disable Style/Documentation

    class ConfigurationFileMissing < Error
      def initialize
        super("Configuration file not found")
      end

      def details
        <<-MESSAGE
active_record_doctor attempted to read a configuration file but could not find
it. Please ensure the file exists and is readable (which includes correct
permissions are set). If it does not exist or it's readable but you still get
this error then consider filing a bug report as active_record_doctor should
not attempt to load non-existent configuration files.
        MESSAGE
      end
    end

    class ConfigurationError < Error
      def initialize(exc)
        @exc = exc
        super("Loading the configuration file resulted in an exception")
      end

      def details
        <<-MESSAGE
The information below comes from the exception raised when the configuration
file was being evaluated. Please try using the details below to fix the error
and retry.

Error class:
#{@exc.class.name}

Error message:
#{@exc.message}

Backtrace:
#{@exc.backtrace.join("\n")}
        MESSAGE
      end
    end

    class ConfigureNotCalled < Error
      def initialize
        super("The configuration file did not call ActiveRecordDoctor.configuration")
      end

      def details
        <<-MESSAGE
active_record_doctor configuration is a Ruby script that MUST call
ActiveRecordDoctor.configuration exactly once. That method was NOT called by
the configuration file in use. If you intend to provide custom configuration
then please ensure that method is called. Otherwise, please delete the
configuration file.
        MESSAGE
      end
    end

    class ConfigureCalledTwice < Error
      def initialize
        super("The configuration file called ActiveRecordDoctor.configuration multiple times")
      end

      def details
        <<-MESSAGE
The configuration file in use has called ActiveRecordDoctor.configure more than
once but should do so EXACTLY ONCE. Please ensure that method is called exactly
once and retry.
        MESSAGE
      end
    end

    class DetectorConfiguredTwice < Error
      def initialize(detector)
        super("Detector #{detector} was configured multiple times")
      end

      def details
        <<-MESSAGE
The configuration file configured the same detector more than once which is
disallowed. Detector configuration should be either:

- absent - to use the defaults
- present exactly once - to override the defaults

Please ensure the detector is configured at most once and retry.
        MESSAGE
      end
    end

    class UnrecognizedDetectorName < Error
      def initialize(detector, recognized_detectors)
        @recognized_detectors = recognized_detectors
        super("Received configuration for an unrecognized detector named #{detector}")
      end

      def details
        <<-MESSAGE
The configuration file provided configuration for an unknown detector. Please
ensure only valid detector names are used and retry.

Currently, the following detectors are recognized:

#{hyphenated_list(@recognized_detectors)}
        MESSAGE
      end
    end

    class UnrecognizedDetectorSettings < Error
      def initialize(detector, unrecognized_settings, recognized_settings)
        @detector = detector
        @unrecognized_settings = unrecognized_settings
        @recognized_settings = recognized_settings
        super("Detector #{detector} received unrecognized settings")
      end

      def details
        <<-MESSAGE
The configuration file provided an unrecognized setting for a detector. Please
ensure only recognized settings are used and retry.

The following settings are not recognized by #{@detector}:

#{hyphenated_list(@unrecognized_settings)}

The complete of settings recognized by #{@detector} is:

#{hyphenated_list(@recognized_settings)}
        MESSAGE
      end
    end

    class UnrecognizedGlobalSetting < Error
      def initialize(name, recognized_settings)
        @recognized_settings = recognized_settings
        super("Global #{name} is unrecognized")
      end

      def details
        <<-MESSAGE
The configuration file set an unrecognized global setting. Please ensure that
only recognized global settings are used and retry.

Currently recognized global settings are:

#{hyphenated_list(@recognized_settings)}
        MESSAGE
      end
    end

    class DuplicateGlobalSetting < Error
      def initialize(name)
        super("Global #{name} was set twice")
      end

      def details
        <<-MESSAGE
The configuration file set the same global setting twice. Each global setting
must be set AT MOST ONCE. Please ensure all global settings are set at most once
and retry.
        MESSAGE
      end
    end

    # rubocop:enable Style/Documentation
  end
end
