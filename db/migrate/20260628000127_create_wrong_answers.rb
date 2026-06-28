class CreateWrongAnswers < ActiveRecord::Migration[8.1]
  def change
    create_table :wrong_answers do |t|
      t.references :question, null: false, foreign_key: true
      t.string :answer_text
      t.integer :count, default: 0, null: false # High-efficiency tracking tally

      t.timestamps
    end
  end
end
