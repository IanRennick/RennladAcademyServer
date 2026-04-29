class Question < ApplicationRecord
  # Different exam question types
  enum :kind, { multiple_choice: 0, open_cloze: 1, word_formation: 2, sentence_cloze: 3 }

  # Associate with Comments
  has_many :comments, as: :commentable, dependent: :destroy
end
