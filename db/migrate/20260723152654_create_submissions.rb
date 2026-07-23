class CreateSubmissions < ActiveRecord::Migration[8.1]
  create_table :submissions do |t|
      t.references :prompt, null: false, foreign_key: true
      
      # Changed column reference handles to bypass the 'student' and 'teacher' enum naming collisions entirely!
      t.references :submitter, null: false, foreign_key: { to_table: :users }
      t.references :corrector, null: true,  foreign_key: { to_table: :users }

      t.string :status, null: false, default: "draft" # draft, submitted, corrected

      # Houses raw student inputs (Plain text essays or Active Storage audio tokens)
      t.text :student_payload

      # Flexible JSONB block handling 4 categories for essays or 5 for speakings dynamically
      t.jsonb :scores, null: false, default: {}

      # Displays exact score adjustments or average bands (+0.5, 4.0, etc.)
      t.float :final_result

      t.timestamps
    end

    # Updated index mapping to track your clean column suffix
    add_index :submissions, [:submitter_id, :status]
  end
end
