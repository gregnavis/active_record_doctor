# frozen_string_literal: true

module ModelFactory
  def self.cleanup
    delete_models
    drop_all_tables
    GC.start
  end

  def self.drop_all_tables
    connection = ActiveRecord::Base.connection
    loop do
      before = connection.tables.size
      break if before.zero?

      attempt_drop_all_tables(connection)
      after = connection.tables.size

      if before == after
        raise("cannot delete temporary tables - most likely due to failing constraints")
      end
    end
  end

  def self.attempt_drop_all_tables(connection)
    connection.tables.each do |table_name|
      ActiveRecord::Migration.suppress_messages do
        begin
          connection.drop_table(table_name, force: :cascade)
        rescue ActiveRecord::InvalidForeignKey, ActiveRecord::StatementInvalid
          # The table cannot be dropped due to foreign key constraints so
          # we'll try to drop it on another attempt.
        end
      end
    end
  end

  def self.delete_models
    Models.empty
  end

  def self.create_table(table_name, options = {}, &block)
    table_name = table_name.to_sym
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Migration.create_table(table_name, **options, &block)
    end
    # Return a proxy object allowing the caller to chain #create_model
    # right after creating a table so that it can be followed by the model
    # definition.
    ModelDefinitionProxy.new(table_name)
  end

  def self.create_model(table_name, &block)
    table_name = table_name.to_sym
    klass = Class.new(ActiveRecord::Base, &block)
    klass_name = table_name.to_s.singularize.classify
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
