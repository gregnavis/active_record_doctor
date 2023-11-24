# frozen_string_literal: true

module ActiveRecordDoctor # :nodoc:
  class << self
    # The config file that's currently being processed by .load_config.
    attr_reader :current_config

    # This method is part of the public API that is intended for use by
    # active_record_doctor users. The remaining methods are considered to be
    # public-not-published.
    def configure(&block)
      # If current_config is set it means that .configure was already called
      # so we must raise an error.
      raise ActiveRecordDoctor::Error::ConfigureCalledTwice if current_config

      # Determine the recognized global and detector settings based on detector
      # metadata. recognizedd_detectors maps detector names to setting names.
      # recognized_globals contains global setting names.
      recognized_detectors = {}
      recognized_globals = []

      ActiveRecordDoctor.detectors.each do |name, detector|
        locals, globals = detector.locals_and_globals

        recognized_detectors[name] = locals
        recognized_globals.concat(globals)
      end

      # The same global can be used by multiple detectors so we must remove
      # duplicates to ensure they aren't reported multiple times via the user
      # interface (e.g. in error messages).
      recognized_globals.uniq!

      # Prepare an empty configuration and call the loader. After .new returns
      # @current_config will contain the configuration provided by the block.
      @current_config = Config.new({}, {})
      Loader.new(current_config, recognized_globals, recognized_detectors, &block)

      # This method is part of the public API expected to be called by users.
      # In order to avoid leaking internal objects, we return an explicit nil.
      nil
    end

    def load_config(path)
      begin
        load(path)
      rescue ActiveRecordDoctor::Error
        raise
      rescue LoadError
        raise ActiveRecordDoctor::Error::ConfigurationFileMissing
      rescue StandardError => e
        raise ActiveRecordDoctor::Error::ConfigurationError[e]
      end
      raise ActiveRecordDoctor::Error::ConfigureNotCalled if current_config.nil?

      # Store the configuration and reset @current_config. We cannot reset
      # @current_config in .configure because that would prevent us from
      # detecting multiple calls to that method.
      config = @current_config
      @current_config = nil

      config
    rescue ActiveRecordDoctor::Error => e
      e.config_path = path
      raise e
    end

    DEFAULT_CONFIG_PATH = File.join(__dir__, "default.rb").freeze
    private_constant :DEFAULT_CONFIG_PATH

    def load_config_with_defaults(path)
      default_config = load_config(DEFAULT_CONFIG_PATH)
      return default_config if path.nil?

      config = load_config(path)
      default_config.merge(config)
    end
  end

  # A class used for loading user-provided configuration files.
  class Loader
    def initialize(config, recognized_globals, recognized_detectors, &block)
      @config = config
      @recognized_globals = recognized_globals
      @recognized_detectors = recognized_detectors
      instance_eval(&block)
    end

    def global(name, value)
      name = name.to_sym

      unless recognized_globals.include?(name)
        raise ActiveRecordDoctor::Error::UnrecognizedGlobalSetting[
          name,
          recognized_globals
        ]
      end

      if config.globals.include?(name)
        raise ActiveRecordDoctor::Error::DuplicateGlobalSetting[name]
      end

      config.globals[name] = value
    end

    def detector(name, settings)
      name = name.to_sym

      recognized_settings = recognized_detectors[name]
      if recognized_settings.nil?
        raise ActiveRecordDoctor::Error::UnrecognizedDetectorName[
          name,
          recognized_detectors.keys
        ]
      end

      if config.detectors.include?(name)
        raise ActiveRecordDoctor::Error::DetectorConfiguredTwice[name]
      end

      unrecognized_settings = settings.keys - recognized_settings
      unless unrecognized_settings.empty?
        raise ActiveRecordDoctor::Error::UnrecognizedDetectorSettings[
          name,
          unrecognized_settings,
          recognized_settings
        ]
      end

      config.detectors[name] = settings
    end

    private

    attr_reader :config, :recognized_globals, :recognized_detectors
  end
end
