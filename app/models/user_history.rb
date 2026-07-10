class UserHistory < ApplicationRecord
  # Associations with user question
  belongs_to :user
  belongs_to :question
end
