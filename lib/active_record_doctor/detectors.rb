# frozen_string_literal: true

require "active_support"
require "active_support/core_ext/class/subclasses"

module ActiveRecordDoctor
  def self.detectors
    @detectors ||=
      begin
        detectors = {}
        ActiveRecordDoctor::Detectors::Base.subclasses.each do |detector|
          detectors[detector.underscored_name] = detector
        end
        detectors
      end
  end

  # Container module for all detectors, implemented as separate classes.
  module Detectors
  end
end
