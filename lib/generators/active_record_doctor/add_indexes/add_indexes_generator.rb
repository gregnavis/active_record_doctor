# frozen_string_literal: true

module ActiveRecordDoctor
  # Generate migrations that add missing indexes to the database.
  class AddIndexesGenerator < Rails::Generators::Base
    desc "Generate migrations for the specified indexes"
    argument :path, type: :string, default: nil, banner: "PATH"

    def create_migrations
      migration_descriptions = read_migration_descriptions(path)
      now = Time.now

      migration_descriptions.each_with_index do |(table, columns), index|
        timestamp = (now + index).strftime("%Y%m%d%H%M%S")
        file_name = "db/migrate/#{timestamp}_index_foreign_keys_in_#{table}.rb"
        create_file(file_name, content(table, columns).tap { |x| puts x })
      end
    end

    private

    INPUT_LINE = /^add an index on (\w+)\.(\w+) - .*$/.freeze
    private_constant :INPUT_LINE

    def read_migration_descriptions(path)
      tables_to_columns = Hash.new { |hash, table| hash[table] = [] }

      File.readlines(path).each_with_index do |line, index|
        next if line.blank?

        match = INPUT_LINE.match(line)
        if match.nil?
          raise("cannot extract table and column name from line #{index + 1}: #{line}")
        end

        table = match[1]
        column = match[2]

        tables_to_columns[table] << column
      end

      tables_to_columns
    end

    def content(table, columns)
      # In order to properly indent the resulting code, we must disable the
      # rubocop rule below.

      <<MIGRATION
class IndexForeignKeysIn#{table.camelize} < ActiveRecord::Migration#{migration_version}
  def change
#{add_indexes(table, columns)}
  end
end
MIGRATION
    end

    def add_indexes(table, columns)
      columns.map do |column|
        add_index(table, column)
      end.join("\n")
    end

    def add_index(table, column)
      index_name = Class.new.extend(ActiveRecord::ConnectionAdapters::SchemaStatements).index_name table, column
      if index_name.size > maximum_index_name_length
        "    add_index :#{table}, :#{column}, name: '#{index_name.first(maximum_index_name_length)}'"
      else
        "    add_index :#{table}, :#{column}"
      end
    end

    def maximum_index_name_length
      connection = ActiveRecord::Base.connection

      case
      when connection.respond_to?(:allowed_index_name_length)
        connection.allowed_index_name_length
      when connection.respond_to?(:index_name_length)
        connection.index_name_length
      else
        raise("cannot determine maximum index name length - an unsupported Active Record version may be in use")
      end
    end

    def migration_version
      if ActiveRecord::VERSION::STRING >= "5.1"
        "[#{ActiveRecord::Migration.current_version}]"
      else
        ""
      end
    end
  end
end
