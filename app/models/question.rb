class Question < ApplicationRecord
  # Associate with Comments
  has_many :comments, as: :commentable, dependent: :destroy
end
