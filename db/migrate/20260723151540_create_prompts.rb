class CreatePrompts < ActiveRecord::Migration[8.1]
  def change
    create_table :prompts do |t|
      t.references :level, null: false, foreign_key: true

      t.string :prompt_type, null: false # "writing" or "speaking"
      t.string :title, null: false       # e.g., "The Impact of Tourism"
      t.string :topic, null: false       # e.g., "tourism", "education", "hobbies"

      # Flexible JSONB block handling your custom variable paragraph parameters
      t.jsonb :metadata, null: false, default: {}

      # Track global utilization metrics across the platform inventory
      t.integer :attempts_count, null: false, default: 0

      t.timestamps
    end

    # Speed up database searches when filtering prompts by type and level
    add_index :prompts, [ :prompt_type, :level_id ]
  end
end
