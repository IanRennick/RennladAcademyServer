class AddLevelToQuestions < ActiveRecord::Migration[8.1]
  def change
    add_reference :questions, :level, null: false, foreign_key: true
  end
end
