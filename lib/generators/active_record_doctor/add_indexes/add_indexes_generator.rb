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
      File.readlines(path).map do |line|
        table, *columns = line.split(" ")
        MigrationDescription.new(table, columns)
      end
    end

    def content(migration_description)
      <<EOF
class IndexForeignKeysIn#{migration_description.table.camelize} < ActiveRecord::Migration
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
  end
end
