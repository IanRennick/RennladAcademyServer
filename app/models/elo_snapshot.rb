# app/models/elo_snapshot.rb
# =========================================================================
# SYSTEM HISTORICAL PROGRESS PERFORMANCE RECORD MODEL
# - Houses daily archival snapshots of global student Elo ratings
# - Leverages structural JSONB fields to log category-specific metrics maps
# =========================================================================
class EloSnapshot < ApplicationRecord
  # --- Associations ---
  belongs_to :user

  # --- Validations ---
  validates :rating, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :recorded_on, presence: true

  # Ensure the category tracking cell initializes as a hash structure if left blank
  before_validation :initialize_category_ratings, on: :create

  private

  # Structural fallback to prevent nil pointer exceptions inside your frontend loops
  def initialize_category_ratings
    self.category_ratings ||= {}
  end
end
