# frozen_string_literal: true

module ActiveRecordDoctor # :nodoc:
  # A class for loading configuration and running detectors.
  class Runner
    def initialize(config)
      @config = config
      @init_called = false
    end

    def run(detector)
      ActiveRecordDoctor.handle_exception do
        call_init
        config = @config.detectors.fetch(detector.underscored_name, {})
        detector.run(config)
      end
    end

    private

    def call_init
      return if @init_called

      @config.init&.call

      @init_called = true
    end
  end
end
