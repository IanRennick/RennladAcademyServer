# app/models/question_tag.rb
# =========================================================================
# GRAPH CURRICULUM RELATIONAL MAPPING REGISTER
# - Serves as the many-to-many join model connecting Questions to Tags
# - Protects data metrics counters from tag calculation profile duplication
# =========================================================================
class QuestionTag < ApplicationRecord
  # --- Associations ---
  belongs_to :question
  belongs_to :tag

  # --- Validations ---
  validates :question_id, presence: true
  validates :tag_id, presence: true

  # DATA GUARD: Enforces structural scoping limits to prevent assigning a duplicate tag to the same question entity
  validates :tag_id, uniqueness: {
    scope: :question_id,
    message: "This specific structural tag string is already associated with the targeted curriculum question profile"
  }
end
