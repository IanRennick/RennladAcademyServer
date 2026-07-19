# app/models/notification.rb
# =========================================================================
# UNIVERSAL REAL-TIME SYSTEM NOTIFICATION REGISTRY MODEL
# - Houses polymorphic notification event payloads and path deep-links
# - Handles target real-time asynchronous Hotwire navbar feed broadcasts
# =========================================================================
class Notification < ApplicationRecord
  # --- Associations ---
  belongs_to :recipient, class_name: "User"
  belongs_to :actor, class_name: "User"

  # --- Whitelist Constants & System Guards ---
  # Strict array list of functional system-supported event type tokens
  VALID_EVENT_TYPES = %w[
    new_chat_message
    public_chat_message
    writing_feedback
    badge_unlock
    system_alert
    new_user_signup
  ].freeze

  # --- Validations ---
  validates :event_type, presence: true, inclusion: {
    in: VALID_EVENT_TYPES,
    message: "%{value} is not a valid, system-supported notification event type token"
  }

  # Ensure custom hash schema fields initialize safely to prevent nil error crashes
  before_validation :initialize_params_payload, on: :create
  validate :prevent_self_notification

  # --- Scopes Matrix ---
  # Scoping filters for lightning-fast database lookups
  scope :unread, -> { where(read_at: nil) }
  scope :recent, -> { order(created_at: :desc).limit(20) }

  # --- Hotwire Real-Time Broadcast Hooks ---
  # Prepends fresh alert row segments downstream to the student's navbar tray instantly in real-time
  after_create_commit do
    broadcast_prepend_to "global_notifications_#{recipient_id}",
                         target: "notifications_feed",
                         partial: "notifications/notification",
                         locals: { notification: self }
  end

  private

  # Structural fallback to ensure JSONB hash methods can execute safely on compile loops
  def initialize_params_payload
    self.params ||= {}
  end

  # Safety filter preventing tracking loops where actors accidentally notify themselves
  def prevent_self_notification
    if recipient_id.present? && actor_id.present? && recipient_id == actor_id && %w[new_chat_message public_chat_message system_alert].include?(event_type)
      errors.add(:recipient_id, "cannot represent the same profile index entity as the target event actor")
    end
  end
end
