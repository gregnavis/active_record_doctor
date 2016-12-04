class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :email
      t.string :first_name
      t.string :last_name
      t.references :profile, foreign_key: true
      t.references :employer, foreign_key: true
      t.string :country_code, null: false

      t.timestamps null: false
    end
    add_index :users, [:last_name, :first_name, :email]
    add_index :users, [:last_name, :first_name]
    add_index :users, [:last_name, :first_name], unique: true, name: :unique_index_on_users_last_name_and_first_name
    add_index :users, :last_name
    add_index :users, :email
    add_index :users, :email, unique: true, name: :unique_index_on_users_email
    add_index :users, [:employer_id, :country_code]
  end
end
