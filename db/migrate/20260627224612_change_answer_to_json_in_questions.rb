class ChangeAnswerToJsonInQuestions < ActiveRecord::Migration[8.1]
  def change
    remove_column :questions, :answer, :string
    add_column :questions, :answers, :json, default: []
  end
end
