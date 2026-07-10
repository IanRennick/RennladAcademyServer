class CreateLevels < ActiveRecord::Migration[8.1]
  def change
    create_table :levels do |t|
      t.string :name, null: false
      t.integer :initial_rating, default: 1200, null: false
      t.text :description

      t.timestamps
    end
    # Forces absolute uniqueness at the database engine level
    add_index :levels, :name, unique: true
  end
end
