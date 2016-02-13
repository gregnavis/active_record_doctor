class CreateEmployers < ActiveRecord::Migration
  def change
    create_table :employers do |t|
      t.string :name

      t.timestamps null: false
    end
  end
end
