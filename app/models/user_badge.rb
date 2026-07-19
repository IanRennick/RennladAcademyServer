# app/models/user_badge.rb
# =========================================================================
# GAMIFICATION LIFECYCLE EARNED BADGES JOIN LAYER MODEL
# - Tracks individual student achievement records and earned milestones
# - Guarantees full data integrity by locking out duplicate badge awards
# =========================================================================
class UserBadge < ApplicationRecord
  # --- Associations ---
  belongs_to :user
  belongs_to :badge

  # --- Validations ---
  validates :user_id, presence: true
  validates :badge_id, presence: true

  # DATA GUARD: Enforces strict scoping rules to prevent awarding the same achievement multiple times
  validates :badge_id, uniqueness: {
    scope: :user_id,
    message: "Achievement milestone already earned!"
  }
end
