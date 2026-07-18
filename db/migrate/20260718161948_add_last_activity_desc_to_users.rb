class AddLastActivityDescToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :last_activity_desc, :string
  end
end
