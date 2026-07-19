# app/models/user_stat.rb
# =========================================================================
# MULTI-DIMENSIONAL PROFICIENCY ACCURACY MATRIX MODEL
# - Houses granular score records tracked by question categories or tags
# - Feeds performance percentage delta gauges on student dashboards
# =========================================================================
class UserStat < ApplicationRecord
  # --- Associations ---
  belongs_to :user

  # --- Validations ---
  validates :stat_type, inclusion: {
    in: %w[kind subtype],
    message: "%{value} must represent a system-supported analytical breakdown axis ('kind' or 'subtype')"
  }

  validates :stat_key, presence: true

  # Numericality Integrity Guards: Lock counters to positive, non-negative whole numbers
  validates :times_done, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :times_correct, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :rating, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # Logical Math Boundary Guard: Prevents impossible metrics from corrupting analytics calculations
  validate :validate_correctness_bounds

  # DATA GUARD: Prevents duplicate matrix category record nodes from registering for the same profile
  validates :stat_key, uniqueness: {
    scope: [ :user_id, :stat_type ],
    message: "This specific tracking statistical node key is already instantiated for this student profile group"
  }

  private

  # Ensures correct attempts never exceed the total attempt count boundary
  def validate_correctness_bounds
    if times_correct.present? && times_done.present? && times_correct > times_done
      errors.add(:times_correct, "cannot mathematically represent a value higher than total times_done logs")
    end
  end
end
