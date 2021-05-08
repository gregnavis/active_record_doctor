# frozen_string_literal: true

require "active_support"
require "active_support/core_ext/class/subclasses"

module ActiveRecordDoctor
  # Container module for all tasks, implemented as separate classes.
  module Tasks
    def self.all
      ActiveRecordDoctor::Tasks::Base.subclasses
    end
  end
end
