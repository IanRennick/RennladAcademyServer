class RenameAndProtectUsername < ActiveRecord::Migration[8.1]
  def change
    # 1. Rename the column cleanly
    rename_column :users, :name, :username

    # 2. Add an explicit unique index rule at the database system level
    add_index :users, :username, unique: true
  end
end
