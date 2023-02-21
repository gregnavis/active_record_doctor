# frozen_string_literal: true

module ActiveRecordDoctor # :nodoc:
  # An excecution environment for active_record_doctor that provides a config
  # and an output device for use by detectors.
  class Runner
    # io is injected via constructor parameters to facilitate testing.
    def initialize(config:, logger:, io: $stdout)
      @config = config
      @logger = logger
      @io = io
    end

    def run_one(name)
      ActiveRecordDoctor.handle_exception do
        ActiveRecordDoctor.detectors.fetch(name).run(
          config: config,
          logger: logger,
          io: io
        )
      end
    end

    def run_all
      success = true

      # We can't use #all? because of its short-circuit behavior - it stops
      # iteration and returns false upon the first falsey value. This
      # prevents other detectors from running if there's a failure.
      ActiveRecordDoctor.detectors.each do |name, _|
        success = false if !run_one(name)
      end

      success
    end

    def help(name)
      detector = ActiveRecordDoctor.detectors.fetch(name)
      io.puts(ActiveRecordDoctor::Help.new(detector))
    end

    private

    attr_reader :config, :logger, :io
  end
end
