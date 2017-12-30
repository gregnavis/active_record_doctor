require_relative 'base_migration'

class CreateEmployers < BaseMigration
  def change
    create_table :employers do |t|
      t.string :name
      t.datetime :deleted_at

      t.timestamps null: false
    end

    add_index :employers, :id, where: 'deleted_at IS NULL'
    add_index :employers, :name, where: 'deleted_at IS NULL'
  end
end
