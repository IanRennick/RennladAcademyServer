class CreateQuestions < ActiveRecord::Migration[8.1]
  def change
    create_table :questions do |t|
      t.string :main
      t.string :answer
      t.integer :attempted, default: 0
      t.integer :correct, default: 0
      t.timestamps
    end
  end
end
