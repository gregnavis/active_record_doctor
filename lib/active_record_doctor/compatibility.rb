module ActiveRecordDoctor
  module Compatibility
    def connection_tables
      if Rails::VERSION::MAJOR == 5
        connection.data_sources
      else
        connection.tables
      end
    end
  end
end
