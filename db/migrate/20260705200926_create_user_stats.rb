class CreateUserStats < ActiveRecord::Migration[8.1]
  def change
    create_table :user_stats do |t|
      t.references :user, null: false, foreign_key: true
      t.string :stat_type, null: false      # Stores either "kind" or "subtype"
      t.integer :stat_key, null: false      # Stores the enum integer value
      t.integer :times_done, default: 0, null: false
      t.integer :times_correct, default: 0, null: false

      t.timestamps
    end

    # Fast indexed search that forces unique entries per type configuration
    add_index :user_stats, [ :user_id, :stat_type, :stat_key ], unique: true
  end
end
