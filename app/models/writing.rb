class Writing < ApplicationRecord
  # Associate with User
  belongs_to :user

  # Associate with Comments
  has_many :comments, dependent: :destroy
end
