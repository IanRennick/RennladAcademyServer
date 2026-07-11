class AddParentIdToComments < ActiveRecord::Migration[8.1]
  def change
    # Adds a parent_id integer column that maps back to parent comments
    add_column :comments, :parent_id, :integer

    # Creates an index to ensure recursive API queries are lightning-fast
    add_index :comments, :parent_id
  end
end
