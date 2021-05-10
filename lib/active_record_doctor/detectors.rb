# frozen_string_literal: true

require "active_support"
require "active_support/core_ext/class/subclasses"

module ActiveRecordDoctor
  # Container module for all detectors, implemented as separate classes.
  module Detectors
    def self.all
      ActiveRecordDoctor::Detectors::Base.subclasses
    end
  end
end
