# frozen_string_literal: true

module ActiveRecordDoctor # :nodoc:
  Config = Struct.new(:globals, :detectors) do
    def merge(config)
      globals = self.globals.merge(config.globals)
      detectors = self.detectors.merge(config.detectors) do |_name, self_settings, config_settings|
        self_settings.merge(config_settings)
      end

      Config.new(globals, detectors)
    end
  end
end
