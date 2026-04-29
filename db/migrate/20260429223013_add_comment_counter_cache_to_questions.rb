class AddCommentCounterCacheToQuestions < ActiveRecord::Migration[8.1]
  def change
    add_column :questions, :comments_count, :integer
  end
end
