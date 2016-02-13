class SpyPrinter
  attr_reader :unindexed_foreign_keys

  def initialize
    @unindexed_foreign_keys = []
  end

  def print_unindexed_foreign_keys(argument)
    @unindexed_foreign_keys << argument
  end
end
