class SpyPrinter
  attr_reader :unindexed_foreign_keys, :extraneous_indexes,
    :missing_foreign_keys, :undefined_table_references

  def initialize
    @unindexed_foreign_keys = nil
    @extraneous_indexes = nil
    @missing_foreign_keys = nil
    @undefined_table_references = nil
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

  def print_missing_foreign_keys(argument)
    if @missing_foreign_keys
      fail("print_missing_foreign_keys cannot be called twice")
    else
      @missing_foreign_keys = argument
    end
  end

  def print_undefined_table_references(argument)
    if @undefined_table_references
      fail("print_undefined_table_references cannot be called twice")
    else
      @undefined_table_references = argument
    end
  end
end
