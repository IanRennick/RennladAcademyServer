class CreateUserBadges < ActiveRecord::Migration[8.1]
  def change
    create_table :user_badges do |t|
      t.references :user, null: false, foreign_key: true
      t.references :badge, null: false, foreign_key: true

      t.timestamps
    end

    # ✅ THE SHIELD INDEX: Guarantees that a User can only link to a specific Badge EXACTLY once!
    add_index :user_badges, [ :user_id, :badge_id ], unique: true
  end
end
