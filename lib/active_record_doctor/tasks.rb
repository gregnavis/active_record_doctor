require "active_support"
require "active_support/core_ext/class/subclasses"

module ActiveRecordDoctor
  module Tasks
    def self.all
      ActiveRecordDoctor::Tasks::Base.subclasses
    end
  end
end
