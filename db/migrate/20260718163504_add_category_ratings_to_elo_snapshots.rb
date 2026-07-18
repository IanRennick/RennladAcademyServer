class AddCategoryRatingsToEloSnapshots < ActiveRecord::Migration[8.1]
  def change
    # null: false and default: {} ensures your data arrays remain reliable and never return nil
    add_column :elo_snapshots, :category_ratings, :jsonb, null: false, default: {}
  end
end
