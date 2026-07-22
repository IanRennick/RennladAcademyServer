# app/models/report.rb
# =========================================================================
# SYSTEM CROWDSOURCED BUG & TYPO REPORTING MODEL
# - Houses user-submitted feedback logs across specific curriculum questions
# - Validates strict text parameters and enforces white-listed token enums
# =========================================================================
class Report < ApplicationRecord
  # --- Relational Database Mappings ---
  belongs_to :user
  belongs_to :question, optional: true

  # --- Structural Data Enums ---
  enum :status, { open: "open", investigating: "investigating", resolved: "resolved" }, default: "open"
  enum :report_type, { typo: "typo", broken_answer: "broken_answer", ui_bug: "ui_bug" }

  # --- Operational Validation Barriers ---
  validates :description, presence: true, length: { minimum: 10, maximum: 1000 }
  validates :report_type, presence: true
end
