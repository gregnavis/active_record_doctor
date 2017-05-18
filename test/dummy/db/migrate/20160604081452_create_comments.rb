require_relative 'base_migration'

class CreateComments < BaseMigration
  def change
    create_table :comments do |t|
      t.references :commentable, polymorphic: true, index: true

      t.timestamps null: false
    end
  end
end
