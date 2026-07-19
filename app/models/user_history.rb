# app/models/user_history.rb
# =========================================================================
# SYSTEM CURRICULUM INTERACTION LOG HISTORY MODEL
# - Serves as the authoritative source of truth for student practice logs
# - Flags failed puzzle attempt strings to populate active review queues
# =========================================================================
class UserHistory < ApplicationRecord
  # --- Associations ---
  belongs_to :user
  belongs_to :question

  # --- Filters Matrix ---
  # Automatically coordinates review flags based on answer correctness
  before_validation :synchronize_review_status, on: :create

  # --- Validations ---
  validates :user_id, presence: true
  validates :question_id, presence: true
  validates :first_attempt_correct, inclusion: { in: [ true, false ] }
  validates :needs_review, inclusion: { in: [ true, false ] }

  # DATA GUARD: Prevents duplicate record event instantiations for a single user/question interaction loop
  validates :question_id, uniqueness: {
    scope: :user_id,
    message: "A practice metrics logging history event is already registered for this specific student-question node pair"
  }

  private

  # Synchronizes your review loops seamlessly if left unassigned by the controller
  def synchronize_review_status
    if first_attempt_correct == false
      self.needs_review = true
    elsif first_attempt_correct == true
      self.needs_review = false
    end
  end
end
