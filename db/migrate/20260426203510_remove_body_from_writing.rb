class RemoveBodyFromWriting < ActiveRecord::Migration[8.1]
  def change
    remove_column :writings, :body, :text
  end
end
