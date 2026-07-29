# app/models/comment_like.rb
class CommentLike < ApplicationRecord
  belongs_to :user
  belongs_to :comment

  # Enforce rigorous database-level single-vote constraints
  validates :user_id, uniqueness: { scope: :comment_id, message: "has already voted on this discussion node" }
end
