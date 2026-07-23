# app/models/submission.rb
# =========================================================================
# UNIFIED EXAMINATION SUBMISSION & GRADING CORE MODEL
# - Manages text essay entries and coordinates speaking audio transcripts
# - Employs a flexible JSONB column to handle variable criteria categories
# - Integrates ActionText rich formatting wrappers to support teacher edits
# =========================================================================
class Submission < ApplicationRecord
  # --- Relational Database Mappings ---
  belongs_to :prompt
  belongs_to :submitter, class_name: "User", foreign_key: :submitter_id
  belongs_to :corrector, class_name: "User", foreign_key: :corrector_id, optional: true

  # --- ActionText Rich Typography Wrappers ---
  # Allows teachers to color-code slip-ups and highlight text on the web pane
  has_rich_text :teacher_feedback

  # --- Structural Data Enums ---
  enum :status, { draft: "draft", submitted: "submitted", corrected: "corrected" }, default: "draft"

  # --- Operational Validation Barriers ---
  validates :status, presence: true
  validates :final_result, numericality: { greater_than_or_equal_to: 0.0, less_than_or_equal_to: 5.0 }, if: :corrected?
  validate :validate_scores_category_distribution, if: :corrected?

  # --- Virtual JSONB Score Dictionary Accessors ---
  def grammar;             scores["grammar"]; end
  def vocabulary;          scores["vocabulary"]; end
  def coherence;           scores["coherence"]; end

  # Writing Only Metric (4 Categories Total)
  def task_achievement;    scores["task_achievement"]; end

  # Speaking Only Metrics (5 Categories Total)
  def pronunciation;       scores["pronunciation"]; end
  def interactive_style;   scores["interactive_style"]; end

  private

  # Validates criteria counts depending on whether the asset maps to a writing or speaking prompt
  def validate_scores_category_distribution
    if prompt.writing?
      # Enforce that all 4 required writing metrics are between 1 and 5
      %w[grammar vocabulary coherence task_achievement].each do |criterion|
        validate_individual_score(criterion)
      end
    elsif prompt.speaking?
      # Enforce that all 5 required speaking metrics are between 1 and 5
      %w[grammar vocabulary coherence pronunciation interactive_style].each do |criterion|
        validate_individual_score(criterion)
      end
    end
  end

  def validate_individual_score(key)
    score_value = scores[key].to_i
    if score_value < 1 || score_value > 5
      errors.add(:scores, "must include a valid score between 1 and 5 for '#{key.humanize.downcase}'")
    end
  end
end
