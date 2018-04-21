require 'temping'

class ActiveSupport::TestCase
  teardown do
    Temping.teardown
  end
end

# Temping 3.10.0 is broken because it removes the tables in the order of
# creation which fails if foreign key constraints are present.
class Temping
  class << self
    alias_method :old_teardown, :teardown

    def teardown
      @model_klasses.reverse!
      old_teardown

      # This hack is required to avoid leaking temporary model classes defined
      # by Temping. If we don't clear the cache then they'll be kept around and
      # returned as valid models which will break tests.
      ActiveSupport::DescendantsTracker.class_variable_get(:@@direct_descendants).clear
    end
  end
end
