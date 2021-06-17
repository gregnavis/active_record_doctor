# frozen_string_literal: true

module ActiveRecordDoctor
  # Rake task for running a detector and reporting its results.
  class Task
    def initialize(detector_class)
      @detector_class = detector_class
    end

    def name
      @detector_class.name.demodulize.underscore.to_sym
    end

    def description
      @detector_class.description
    end

    def run
      @detector_class.run
    end
  end
end
