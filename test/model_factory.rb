module ModelFactory
  def self.cleanup
    delete_models
    drop_all_tables
    GC.start
  end

  def self.drop_all_tables
    ActiveRecord::Base.connection.tables.each do |table_name|
      ActiveRecord::Migration.suppress_messages do
        ActiveRecord::Base.connection.drop_table(table_name, force: :cascade)
      end
    end
  end

  def self.delete_models
    Models.empty
  end

  def self.create_table(table_name, &block)
    table_name = table_name.to_sym
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Migration.create_table(table_name, &block)
    end

    # Return a proxy object allowing the caller to chain #create_model
    # right after creating a table so that it can be followed by the model
    # definition.
    ModelDefinitionProxy.new(table_name)
  end

  def self.create_model(table_name, &block)
    table_name = table_name.to_sym
    klass = Class.new(ActiveRecord::Base, &block)
    klass_name = table_name.to_s.classify
    Models.const_set(klass_name, klass)
  end

  class ModelDefinitionProxy
    def initialize(table_name)
      @table_name = table_name
    end

    def create_model(&block)
      ModelFactory.create_model(@table_name, &block)
    end
  end

  module Models
    def self.empty
      constants.each do |name|
        remove_const(name)
      end
    end
  end
end