class Comment < ApplicationRecord
  # Associate with parent
  delegated_type :commentable, types: %w[Question Writing], counter_cache: true

  # Associate with user
  belongs_to :user

  # Comment body is rich text
  has_rich_text :body

  # The Self-Referencing Relationship Tree
  # A reply comment optionally belongs to a single parent comment
  belongs_to :parent, class_name: "Comment", optional: true

  # A parent comment can have many child reply comments nested beneath it
  has_many :replies, class_name: "Comment", foreign_key: "parent_id", dependent: :destroy

  # Scope to pull ONLY the main thread starters, skipping child replies
  scope :root_threads, -> { where(parent_id: nil) }
end
