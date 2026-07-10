class WrongAnswer < ApplicationRecord
  # Association with question
  belongs_to :question

  # Validate inputs
  validates :answer_text, presence: true
end
