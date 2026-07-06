class Tag < ApplicationRecord
  # Validate the tag is a unique name ignoring case
  validates :name, presence: true, uniqueness: { case_sensitive: false }

  # Associations with question tags and questions
  has_many :question_tags, dependent: :destroy
  has_many :questions, through: :question_tags
end
