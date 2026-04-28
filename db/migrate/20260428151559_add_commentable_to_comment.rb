class AddCommentableToComment < ActiveRecord::Migration[8.1]
  def change
    add_reference :comments, :commentable, polymorphic: true, null: false
  end
end
