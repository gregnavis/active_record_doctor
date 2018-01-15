module ActiveRecordDoctor
  module Tasks
    def self.all
      ActiveRecordDoctor::Tasks::Base.subclasses
    end
  end
end
