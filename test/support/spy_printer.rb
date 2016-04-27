class SpyPrinter
  attr_reader :unindexed_foreign_keys, :extraneous_indexes

  def initialize
    @unindexed_foreign_keys = nil
    @extraneous_indexes = nil
  end

  def print_unindexed_foreign_keys(argument)
    if @unindexed_foreign_keys
      fail("print_unindexed_foreign_keys cannot be called twice")
    else
      @unindexed_foreign_keys = argument
    end
  end

  def print_extraneous_indexes(argument)
    if @extraneous_indexes
      fail("print_extraneous_indexes cannot be called twice")
    else
      @extraneous_indexes = argument
    end
  end
end
