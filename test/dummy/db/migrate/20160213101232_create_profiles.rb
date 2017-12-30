require_relative 'base_migration'

class CreateProfiles < BaseMigration
  def change
    create_table :profiles do |t|
      t.string :first_name
      t.string :last_name
      t.datetime :deleted_at

      t.timestamps null: false
    end

    add_index :profiles, [:first_name, :last_name]
  end
end
