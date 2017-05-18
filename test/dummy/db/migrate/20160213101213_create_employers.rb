require_relative 'base_migration'

class CreateEmployers < BaseMigration
  def change
    create_table :employers do |t|
      t.string :name

      t.timestamps null: false
    end

    add_index :employers, :id
  end
end
