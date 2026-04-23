class Comment < ApplicationRecord
  # Associate with parent
  belongs_to :writing

  # Associate with user
  belongs_to :user

  # Comment body is rich text
  has_rich_text :body
end
