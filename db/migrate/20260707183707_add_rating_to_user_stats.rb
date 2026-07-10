class AddRatingToUserStats < ActiveRecord::Migration[8.1]
  def change
    add_column :user_stats, :rating, :integer, default: 1200, null: false
  end
end
