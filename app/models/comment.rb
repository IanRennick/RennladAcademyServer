class Comment < ApplicationRecord
  # Associate with parent
  delegated_type :commentable, types: %w[Question Writing], counter_cache: true

  # Associate with user
  belongs_to :user

  # Comment body is rich text
  has_rich_text :body
end
