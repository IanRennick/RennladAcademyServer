class AddCommentCounterCacheToWritings < ActiveRecord::Migration[8.1]
  def change
    add_column :writings, :comments_count, :integer
  end
end
