class QuestionTag < ApplicationRecord
  # Associations with tags and questions
  belongs_to :question
  belongs_to :tag
end
