# frozen_string_literal: true

module ActiveRecordDoctor
  module Utils # :nodoc:
    class << self
      def postgresql?(connection = ActiveRecord::Base.connection)
        ["PostgreSQL", "PostGIS"].include?(connection.adapter_name)
      end

      def mysql?(connection = ActiveRecord::Base.connection)
        connection.adapter_name == "Mysql2"
      end

      def sqlite?(connection = ActiveRecord::Base.connection)
        connection.adapter_name == "SQLite"
      end
    end
  end
end
