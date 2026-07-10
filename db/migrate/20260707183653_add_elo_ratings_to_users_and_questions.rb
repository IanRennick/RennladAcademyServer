class AddEloRatingsToUsersAndQuestions < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :rating, :integer, default: 1200, null: false
    add_column :questions, :rating, :integer, default: 1200, null: false
  end
end
