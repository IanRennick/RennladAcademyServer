class AddLevelToUsers < ActiveRecord::Migration[8.1]
  def change
    # 1. Step A: Create the column allowing NULL values temporarily
    add_reference :users, :level, null: true, foreign_key: true

    # 2. Step B: Dynamically fetch your B2 Level record row via primitive SQL
    # This avoids loading model code blocks before tables are finalized!
    b2_record = execute("SELECT id FROM levels WHERE lower(name) = 'b2' LIMIT 1").first
    b2_id = b2_record ? b2_record["id"] : nil

    if b2_id.present?
      # Backfill your 5 test users right away now that the column exists!
      execute("UPDATE users SET level_id = #{b2_id} WHERE level_id IS NULL")

      # Set B2 as the automatic system default for all future user signups
      change_column_default :users, :level_id, from: nil, to: b2_id
    end

    # 3. Step C: Enforce non-null database schema integrity now that columns are full!
    change_column_null :users, :level_id, false
  end
end
