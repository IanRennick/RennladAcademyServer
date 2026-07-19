# app/models/wrong_answer.rb
# =========================================================================
# CURRICULUM ANALYTICS DISTRACTOR REGISTRY MODEL
# - Logs and aggregates individual incorrect text strings submitted by students
# - Feeds frequency tracking data blocks to identify systemic grammar errors
# =========================================================================
class WrongAnswer < ApplicationRecord
  # --- Associations ---
  belongs_to :question

  # --- Validations ---
  validates :answer_text, presence: true
  validates :count, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1 }

  # DATA GUARD: Enforces strict unique scoped boundaries to prevent cloning identical wrong strings for the same puzzle
  validates :answer_text, uniqueness: {
    scope: :question_id,
    message: "This specific distractor text string is already registered and tracked under this curriculum question entity"
  }
end
