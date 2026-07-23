# app/models/prompt.rb
# =========================================================================
# UNIFIED CURRICULUM EXAMINATION PROMPT REGISTRY MODEL
# - Houses variable task directives for both speaking and writing exams
# - Utilizes a PostgreSQL jsonb block to store chaotic paragraph data
# - Features Active Storage macros to securely bind image attachments
# =========================================================================
class Prompt < ApplicationRecord
  # --- Relational Database Mappings ---
  belongs_to :level

  # --- Active Storage Directives ---
  has_one_attached :photo

  # --- Structural Data Enums ---
  enum :prompt_type, { writing: "writing", speaking: "speaking" }

  # --- Operational Validation Barriers ---
  validates :title, :topic, :prompt_type, presence: true
  validates :attempts_count, numericality: { greater_than_or_equal_to: 0 }
  validate :validate_metadata_schema_integrity

  # --- Virtual JSONB Schema Accessors ---
  def situation;       metadata["situation"]; end
  def word_count;      metadata["word_count"]; end
  def bullet_points;   metadata["bullet_points"] || []; end
  def instructions;    metadata["instructions"] || []; end
  def assignment_type; metadata["assignment_type"]; end # essay, review, article etc.

  # Maps a short follow-up or lead-in question directly to a speaking photo task
  def question;        metadata["question"]; end

  private

  # Enforces structural data sanity inside the JSONB matrix depending on the task type
  def validate_metadata_schema_integrity
    if writing?
      errors.add(:metadata, "must include a situation string") if metadata["situation"].blank?
      errors.add(:metadata, "must specify an assignment type") if metadata["assignment_type"].blank?
    elsif speaking?
      # Enforce that an interactive speaking card must have its targeted question registered
      errors.add(:metadata, "must include a speaking prompt question text string") if metadata["question"].blank?

      unless photo.attached? || metadata["image_url"].present?
        errors.add(:base, "Speaking prompts require an attached photo asset or an image URL link")
      end
    end
  end
end
