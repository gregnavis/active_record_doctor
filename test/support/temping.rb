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
    end
  end
end
