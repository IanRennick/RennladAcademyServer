# app/models/tag.rb
# =========================================================================
# SYSTEM GRAMMATICAL TOPIC TAG DIRECTORY MODEL
# - Houses global tracking strings (e.g. "conditionals", "passives")
# - Automatically sanitizes inputs into standardized lowercase tracking strings
# =========================================================================
class Tag < ApplicationRecord
  # --- Associations ---
  # If a master tag is dropped, its connecting map coordinates are cleared instantly
  has_many :question_tags, dependent: :destroy
  has_many :questions, through: :question_tags

  # --- Sanitization Filters ---
  # Automatically formats tag inputs cleanly before validations execute
  before_validation :sanitize_tag_name, if: :name_present?

  # --- Validations ---
  validates :name, presence: true, uniqueness: { case_sensitive: false }

  # Strict Whitelist Regex Guard: Enforces words to be single, lowercase alphanumeric strings without spaces
  VALID_TAG_REGEX = /\A[a-z0-9_\-]+\z/
  validates :name, format: {
    with: VALID_TAG_REGEX,
    message: "must represent a single lowercase alphanumeric word profile string with no spaces or special character blocks"
  }

  private

  def name_present?
    name.present?
  end

  # Strips whitespace, downcases characters, and removes leading hashtags or punctuation clutter
  def sanitize_tag_name
    self.name = name.to_s.strip.downcase.gsub(/\A#+/, "").gsub(/[^a-z0-9_\-]/, "")
  end
end
