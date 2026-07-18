class CreateBadges < ActiveRecord::Migration[8.1]
  def change
    create_table :badges do |t|
      t.string :name
      t.string :description
      t.string :icon
      t.string :milestone_type
      t.integer :milestone_threshold

      t.timestamps
    end
  end
end
