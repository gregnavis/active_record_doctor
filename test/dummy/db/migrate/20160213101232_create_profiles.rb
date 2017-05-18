require_relative 'base_migration'

class CreateProfiles < BaseMigration
  def change
    create_table :profiles do |t|
      t.string :first_name
      t.string :last_name

      t.timestamps null: false
    end
  end
end
