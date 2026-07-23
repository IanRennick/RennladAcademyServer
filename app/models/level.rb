# app/models/level.rb
# =========================================================================
# CEFR DIFFICULTY TIER MATRIX REGISTRY MODEL
# - Maps master proficiency groups (B1, B2, C1, C2)
# - Standardizes user inputs into sanitized uppercase formatting anchors
# =========================================================================
class Level < ApplicationRecord
  # --- Associations ---
  has_many :questions, dependent: :nullify
  has_many :prompts, dependent: :destroy

  # --- Sanitization Filters ---
  before_validation { self.name = name.to_s.upcase.strip if name.present? }

  # --- Validations ---
  validates :name, presence: true, uniqueness: { case_sensitive: false }

  VALID_CEFR_REGEX = /\A[A-C][1-2]\z/
  validates :name, format: {
    with: VALID_CEFR_REGEX,
    message: "must represent a valid system-supported CEFR code format profile string (e.g. B2, C1)"
  }
end
