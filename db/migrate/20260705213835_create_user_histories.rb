class CreateUserHistories < ActiveRecord::Migration[8.1]
  def change
    create_table :user_histories do |t|
      t.references :user, null: false, foreign_key: true
      t.references :question, null: false, foreign_key: true
      t.boolean :first_attempt_correct, null: false
      t.boolean :needs_review, default: false, null: false # The frontend toggle switch
      t.string :original_wrong_answer                      # Stores their first mistake

      t.timestamps
    end

    # Crucial index: Guarantees a user only gets ONE first-try row per puzzle
    add_index :user_histories, [ :user_id, :question_id ], unique: true
  end
end
