# frozen_string_literal: true

module ModelFactory
  def create_table(*args, &block)
    ModelFactory.create_table(*args, &block)
  end

  def create_model(*args, &block)
    ModelFactory.create_model(*args, &block)
  end

  def cleanup_models
    ModelFactory.cleanup_models
  end

  def self.cleanup_models
    delete_models
    drop_all_tables
    GC.start
  end

  def self.drop_all_tables
    connection = ActiveRecord::Base.connection
    loop do
      before = connection.data_sources.size
      break if before.zero?

      try_drop_all_tables_and_views(connection)
      remaining_data_sources = connection.data_sources
      after = remaining_data_sources.size

      # rubocop:disable Style/Next
      if before == after
        raise(<<~ERROR)
          Cannot delete temporary tables - most likely due to failing constraints. Remaining tables and views:

          #{remaining_data_sources.join("\n")}
        ERROR
      end
      # rubocop:enable Style/Next
    end
  end

  def self.try_drop_all_tables_and_views(connection)
    connection.data_sources.each do |table_name|
      try_drop_table(connection, table_name) || try_drop_view(connection, table_name)
    end
  end

  def self.try_drop_table(connection, table_name)
    ActiveRecord::Migration.suppress_messages do
      begin
        connection.drop_table(table_name, force: :cascade)
        true
      rescue ActiveRecord::InvalidForeignKey, ActiveRecord::StatementInvalid
        # The table cannot be dropped due to foreign key constraints so
        # we'll try to drop it on another attempt.
        false
      end
    end
  end

  def self.try_drop_view(connection, view_name)
    ActiveRecord::Migration.suppress_messages do
      begin
        connection.execute("DROP VIEW #{view_name}")
        true
      rescue ActiveRecord::InvalidForeignKey, ActiveRecord::StatementInvalid
        # The table cannot be dropped due to foreign key constraints so
        # we'll try to drop it on another attempt.
        false
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
