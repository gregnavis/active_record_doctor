module ActiveRecordDoctor
  class AddIndexesGenerator < Rails::Generators::Base
    MigrationDescription = Struct.new(:table, :columns)

    desc 'Generate migrations for the specified indexes'
    argument :path, type: :string, default: nil, banner: 'PATH'

    def create_migrations
      migration_descriptions = read_migration_descriptions(path)
      now = Time.now

      migration_descriptions.each_with_index do |migration_description, index|
        timestamp = (now + index).strftime("%Y%m%d%H%M%S")
        file_name = "db/migrate/#{timestamp}_index_foreign_keys_in_#{migration_description.table}.rb"
        create_file(file_name, content(migration_description))
      end
    end

    private

    def read_migration_descriptions(path)
      File.readlines(path).each_with_index.map do |line, index|
        table, *columns = line.split(/\s+/)

        if table.empty?
          fail("No table name in #{path} on line #{index + 1}. Ensure the line doesn't start with whitespace.")
        end
        if columns.empty?
          fail("No columns for table #{table} in #{path} on line #{index + 1}.")
        end

        MigrationDescription.new(table, columns)
      end
    end

    def content(migration_description)
      <<EOF
class IndexForeignKeysIn#{migration_description.table.camelize} < ActiveRecord::Migration#{migration_version}
  def change
#{add_indexes(migration_description)}
  end
end
EOF
    end

    def add_indexes(migration_description)
      migration_description.columns.map do |column|
        add_index(migration_description.table, column)
      end.join("\n")
    end

    def add_index(table, column)
      "    add_index :#{table}, :#{column}"
    end

    def migration_version
      major = ActiveRecord::VERSION::MAJOR
      minor = ActiveRecord::VERSION::MINOR
      if major >= 5 && minor >= 1
        "[#{major}.#{minor}]"
      else
        ''
      end
    end
  end
end
