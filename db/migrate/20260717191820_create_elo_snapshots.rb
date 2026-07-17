class CreateEloSnapshots < ActiveRecord::Migration[8.1]
  def change
    create_table :elo_snapshots do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :rating, null: false, default: 1200
      t.date :recorded_on, null: false

      t.timestamps
    end

    # ✅ CORE DATABASE SHIELD: A student can only have one snapshot row per unique calendar date!
    add_index :elo_snapshots, [ :user_id, :recorded_on ], unique: true
  end
end
