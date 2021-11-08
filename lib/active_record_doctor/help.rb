# frozen_string_literal: true

module ActiveRecordDoctor
  # Turn a detector class into a human-readable help text.
  class Help
    def initialize(klass)
      @klass = klass
    end

    def to_s
      <<-HELP
#{klass.underscored_name} - #{klass.description}

Configuration options:
#{config_to_s}
      HELP
    end

    private

    attr_reader :klass

    GLOBAL_COMMENT = "local and global"
    LOCAL_COMMENT = "local only"

    def config_to_s
      klass.config.map do |key, metadata|
        type =
          if metadata[:global]
            GLOBAL_COMMENT
          else
            LOCAL_COMMENT
          end

        "  - #{key} (#{type}) - #{metadata.fetch(:description)}"
      end.join("\n")
    end
  end
end
