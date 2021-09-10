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
    def self.[](*args)
      new(*args)
    end

    def user_message
      "active_record_doctor aborted due to the following error:\n" \
      "#{message}\n" \
      "\n" \
      "Configuration file:\n" \
      "#{path_or_message}\n" \
      "\n" \
      "Additional information:\n" \
      "#{details}\n"
    end

    private

    def path_or_message
      @path || "no configuration file in use (using default settings)"
    end
  end

  class Error
    # We don't need extra documentation for error classes because of their
    # extensive error messages.
    # rubocop:disable Style/Documentation

    class ConfigurationError < Error
      def initialize(path, exc)
        @path = path
        @exc = exc
        super("Loading the configuration file resulted in an exception.")
      end

      def details
        "The information below comes from the exception that was raised when loading\n" \
        "the configuration file. Please fix the problem and retry.\n" \
        "\n" \
        "Error class:\n" \
        "#{@exc.class.name}\n" \
        "\n" \
        "Error message:\n" \
        "#{@exc.message}\n" \
        "\n" \
        "Backtrace:\n" \
        "#{@exc.backtrace.join("\n")}\n"
      end
    end

    class ConfigureNotCalled < Error
      def initialize(path)
        @path = path
        super("The configuration file must call ActiveRecordDoctor.configure but it did not.")
      end

      def details
        "The active_record_doctor config file is a Ruby script that MUST call\n" \
        "ActiveRecordDoctor.configure exactly once. The aforementioned file does exist\n" \
        "but it DOES NOT seem to call that method at all. If you intended to provide\n" \
        "custom active_record_doctor configuration then ensure the method is called\n" \
        "exactly once. Otherwise, delete the configuration file to avoid confusion."
      end
    end

    class ConfigureCalledTwice < Error
      def initialize(path)
        @path = path
        super(
          "The configuration file must call ActiveRecordDoctor.configure at most once but\n" \
          "did so multiple times."
        )
      end

      def details
        "The active_record_doctor config file has called ActiveRecordDoctor.configure\n" \
        "more than once but should do so exactly once. Please fix the configuration file\n" \
        "and retry."
      end
    end

    class InitConfiguredTwice < Error
      def initialize(path)
        @path = path
        super(
          "The configuration provided the init hook multiple times but should do so at most\n" \
          "ONCE. Please fix the configuration file and retry."
        )
      end

      def details
        "The init hook is used to load all models and make them available to\n" \
        "active_record_doctor for inspection. In Rails apps the default is to use the\n" \
        "Rails-provided eager loading features. A custom init hook is usually not\n" \
        "required. Non-Rails apps must provide an init hook through the configuration\n" \
        "file to allow active_record_doctor to work.\n" \
        "\n" \
        "The hook can be specified at most once and it seems your configuration file\n" \
        "provides it multiple times. Please ensure it's used at most once and retry."
      end
    end

    class DetectorConfiguredTwice < Error
      def initialize(path, detector)
        @path = path
        super("#{detector} received configuration multiple times")
      end

      def details
        "The configuration file provided settings for the same detector multiple times.\n" \
        "This is disallowed - a detector configuration must be either absent (to use the\n" \
        "defaults) or provided exactly once (to override the defaults). Please ensure\n" \
        "all detectors are configured at most once and retry."
      end
    end

    class UnrecognizedDetectorName < Error
      def initialize(path, detector, recognized_detectors)
        @path = path
        @recognized_detectors = recognized_detectors
        super("Received configuration for an unrecognized detector named #{detector}")
      end

      def details
        "The configuration file attempted to configure an unknown detector. Please ensure\n" \
        "only valid detector names are used and retry.\n" \
        "\n" \
        "Currently, the following detectors are recognized:\n" \
        "\n" \
        "#{@recognized_detectors.map { |name| "  - #{name}\n" }.join}"
      end
    end

    class UnrecognizedDetectorSettings < Error
      def initialize(path, detector, unrecognized_settings, recognized_settings)
        @path = path
        @detector = detector
        @unrecognized_settings = unrecognized_settings
        @recognized_settings = recognized_settings
        super("#{detector} received unrecognized settings.")
      end

      def details
        "The configuration file passed one or more unknown setting for the aforementioned\n" \
        "detector. Please ensure only recognized settings are used and retry.\n" \
        "\n" \
        "Unrecognized settings found in the configuration file:\n" \
        "\n" \
        "#{@unrecognized_settings.map { |name| "  - #{name}\n" }.join}" \
        "\n" \
        "Settings recognized by #{@detector} are:\n" \
        "\n" \
        "#{@recognized_settings.map { |name| "  - #{name}\n" }.join}"
      end
    end

    # rubocop:enable Style/Documentation
  end
end
