# frozen_string_literal: true

module ActiveRecordDoctor # :nodoc:
  Config = Struct.new(:init, :detectors)

  class << self
    attr_reader :config

    def configure(&block)
      raise ActiveRecordDoctor::Error::ConfigureCalledTwice[@path] if @config

      @config = Config.new(nil, {})

      Loader.new(@path, @config, &block)

      # This method is part of the public API expected to be called by users.
      # In order to avoid leaking internal objects, we return an explicit nil.
      nil
    end

    def load_config(path)
      raise ".load_config was already called" if @config

      @path = path
      begin
        load(path)
      rescue ActiveRecordDoctor::Error
        raise
      rescue StandardError => e
        raise ActiveRecordDoctor::Error::ConfigurationError[path, e]
      end
      raise ActiveRecordDoctor::Error::ConfigureNotCalled[path] unless defined?(@config)

      @config
    end
  end

  # A class used for loading user-provided configuration files.
  class Loader
    attr_reader :detectors

    def initialize(path, config)
      @path = path
      @config = config
      yield(self)
    end

    def init(&block)
      raise ActiveRecordDoctor::Error::InitConfiguredTwice[@path] if @config.init

      @config.init = block
    end

    def detector(name, config)
      name = name.to_sym

      if @config.detectors.include?(name)
        raise ActiveRecordDoctor::Error::DetectorConfiguredTwice[@path, name]
      end

      detector = ActiveRecordDoctor.detectors[name]
      if detector.nil?
        raise ActiveRecordDoctor::Error::UnrecognizedDetectorName[
          @path,
          name,
          ActiveRecordDoctor.detectors.keys
        ]
      end

      unrecognized_keys = config.keys.reject do |key|
        detector.config.include?(key)
      end
      unless unrecognized_keys.empty?
        raise ActiveRecordDoctor::Error::UnrecognizedDetectorSettings[
          @path,
          name,
          unrecognized_keys,
          detector.recognized_settings
        ]
      end

      @config.detectors[name] = config
    end
  end
end
