class Writing < ApplicationRecord
  # Associate with User
  belongs_to :user

  # Associate with Comments
  has_many :comments, as: :commentable, dependent: :destroy

  # Writing body is rich text
  has_rich_text :body
end
