# app/models/badge.rb
# =========================================================================
# AUTHORITATIVE GAMIFICATION BADGE REGISTRY MODEL
# - Defines master award medals (e.g., "Grammar Cadet", "Puzzle Veteran")
# - Tracks achievement requirements through a flexible milestone system
# =========================================================================
class Badge < ApplicationRecord
  # --- Associations ---
  # Standard Join Table connection linking students to unlocked medals
  has_many :user_badges, dependent: :destroy
  has_many :users, through: :user_badges

  # --- Validations ---
  validates :name, presence: true, uniqueness: true
  validates :milestone_threshold, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validates :milestone_type, presence: true

  # Whitelist of strict, system-supported achievement conditions to block junk string injections
  VALID_MILESTONE_TYPES = %w[total_questions high_elo total_writings].freeze
  validates :milestone_type, inclusion: {
    in: VALID_MILESTONE_TYPES,
    message: "%{value} is not a supported, functional milestone execution route"
  }
end
