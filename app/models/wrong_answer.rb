# app/models/wrong_answer.rb
class WrongAnswer < ApplicationRecord
  belongs_to :question

  # Clean user string data before evaluating
  validates :answer_text, presence: true
end
