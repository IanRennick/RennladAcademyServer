# app/models/user_tag_stat.rb
# =========================================================================
# MULTI-DIMENSIONAL GRAMMAR TAG ANALYTICS REGISTER MODEL
# - Stores complex structured tracking hashes inside a JSONB database column
# - Format schema layout: { "tag_name" => { "correct" => 5, "done" => 10, "rating" => 1250 } }
# =========================================================================
class UserTagStat < ApplicationRecord
  # --- Associations ---
  belongs_to :user

  # --- Validations & Constraints ---
  validates :user_id, presence: true, uniqueness: {
    message: "A grammar tag statistics tracking cache matrix is already registered for this specific student profile"
  }

  # Ensure the serialized json field initializes as a secure hash structure if left blank
  before_validation :initialize_stats_json, on: :create

  private

  # Structural fallback to prevent nil pointer exceptions inside your frontend calculation loops
  def initialize_stats_json
    self.stats_json ||= {}
  end
end
