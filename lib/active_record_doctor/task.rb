# frozen_string_literal: true

module ActiveRecordDoctor
  # Rake task for running a detector and reporting its results.
  class Task
    DEFAULT_PRINTER = ActiveRecordDoctor::Printers::IOPrinter.new

    def initialize(detector_class, printer = DEFAULT_PRINTER)
      @detector_class = detector_class
      @printer = printer
    end

    def name
      @detector_class.name.demodulize.underscore.to_sym
    end

    def description
      @detector_class.description
    end

    def run
      problems, options = @detector_class.run
      @printer.public_send(name, problems, options)

      problems.empty?
    end
  end
end
