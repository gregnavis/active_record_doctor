if ActiveRecord::VERSION::MAJOR >= 5 && ActiveRecord::VERSION::MINOR >= 1
  BaseMigration = ActiveRecord::Migration[4.2]
else
  BaseMigration = ActiveRecord::Migration
end
