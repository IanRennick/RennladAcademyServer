# app/models/comment.rb
# =========================================================================
# UNIVERSAL POLYMORPHIC FORUM DISCUSSION CONVERSATION MODEL
# - Implements Rails delegated_type profiles linking Questions and Writings
# - Features a recursive self-referencing relationship framework tree for sub-replies
# =========================================================================
class Comment < ApplicationRecord
  # --- Polymorphic Delegation Matrix ---
  # Connects parent targets cleanly while maintaining database counter caches
  delegated_type :commentable, types: %w[Question Writing], counter_cache: true

  # --- Associations ---
  belongs_to :user

  # A child reply optionally belongs to a single parent thread comment starter
  belongs_to :parent, class_name: "Comment", optional: true

  # A parent comment cascades deletions down to all nested replies below it
  has_many :replies, class_name: "Comment", foreign_key: "parent_id", dependent: :destroy

  # --- ActionText Rich Text Integration ---
  has_rich_text :body

  # --- Data Guard Shields & Validations ---
  validates :body, presence: true
  validate :prevent_self_referential_loop

  # --- Scopes Matrix ---
  # Filters the global registry stream to fetch ONLY the main conversation threads
  scope :root_threads, -> { where(parent_id: nil) }

  private

  # Prevents a comment node from linking to itself, blocking database trace system infinite loops
  def prevent_self_referential_loop
    if id.present? && parent_id == id
      errors.add(:parent_id, "cannot form a self-referential loops index handle mapping context")
    end
  end
end
