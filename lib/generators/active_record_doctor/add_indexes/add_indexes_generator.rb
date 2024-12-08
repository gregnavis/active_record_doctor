# frozen_string_literal: true

module ActiveRecordDoctor
  # Generate migrations that add missing indexes to the database.
  class AddIndexesGenerator < Rails::Generators::Base
    desc "Generate migrations for the specified indexes"
    argument :path, type: :string, default: nil, banner: "PATH"

    def create_migrations
      migration_descriptions = read_migration_descriptions(path)
      now = Time.now

      migration_descriptions.each_with_index do |(table, indexes), index|
        timestamp = (now + index).strftime("%Y%m%d%H%M%S")
        file_name = "db/migrate/#{timestamp}_index_foreign_keys_in_#{table}.rb"
        create_file(file_name, content(table, indexes).tap { |x| puts x })
      end
    end

    private

    INPUT_LINE = /^add an index on (\w+)\((.+)\) - .*$/
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
        columns = match[2].split(",").map(&:strip)

        tables_to_columns[table] << columns
      end

      tables_to_columns
    end

    def content(table, indexes)
      # In order to properly indent the resulting code, we must disable the
      # rubocop rule below.

      <<MIGRATION
class IndexForeignKeysIn#{table.camelize} < ActiveRecord::Migration[#{ActiveRecord::Migration.current_version}]
  def change
#{add_indexes(table, indexes)}
  end
end
MIGRATION
    end

    def add_indexes(table, indexes)
      indexes.map do |columns|
        add_index(table, columns)
      end.join("\n")
    end

    def add_index(table, columns)
      connection = ActiveRecord::Base.connection

      index_name = connection.index_name(table, columns)
      if index_name.size > connection.index_name_length
        "    add_index :#{table}, #{columns.inspect}, name: '#{index_name.first(connection.index_name_length)}'"
      else
        "    add_index :#{table}, #{columns.inspect}"
      end
    end
  end
end
