# app/models/participant.rb
# =========================================================================
# SECURE DIRECT CHATROOM JOIN TABLE COHORT REGISTRY MODEL
# - Maps student profiles to isolated room access control tokens
# - Serves as the primary validation query gate for message streams
# =========================================================================
class Participant < ApplicationRecord
  # --- Associations ---
  belongs_to :user
  belongs_to :room

  # --- Validations ---
  validates :user_id, presence: true
  validates :room_id, presence: true

  # DATA GUARD: Enforces full scoping constraints to block duplicate user rows within a single room entity
  validates :user_id, uniqueness: {
    scope: :room_id,
    message: "Student account entity is already assigned as an active participant inside this targeted room channel"
  }
end
