class AddCorrectOnAnyAttemptToUserHistories < ActiveRecord::Migration[8.1]
  def change
    add_column :user_histories, :correct_on_any_attempt, :boolean
  end
end
