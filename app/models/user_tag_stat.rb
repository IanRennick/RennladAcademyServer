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

  # Returns an array of the top 5 weakest categories based on lowest success ratios
  def top_weak_categories(limit = 5)
    return [] if stats_json.blank?

    category_scores = []

    stats_json.each do |category, metrics|
      correct = metrics["correct"].to_f
      incorrect = metrics["incorrect"].to_f
      total = correct + incorrect

      next if total.zero? # Skip categories with no attempts yet

      # Calculate accuracy percentage (lower percentage = greater weakness)
      success_rate = correct / total
      category_scores << { category: category, rate: success_rate }
    end

    # Sort ascending (lowest success rate first) and grab the top categories
    sorted_weaknesses = category_scores.sort_by { |item| item[:rate] }.first(limit)
    sorted_weaknesses.map { |item| item[:category] }
  end

  private

  # Structural fallback to prevent nil pointer exceptions inside your frontend calculation loops
  def initialize_stats_json
    self.stats_json ||= {}
  end
end
