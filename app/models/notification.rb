class Notification < ApplicationRecord
  belongs_to :recipient, class_name: "User"
  belongs_to :actor, class_name: "User"

  validates :event_type, presence: true

  # Scoping filters for lightning-fast database lookups
  scope :unread, -> { where(read_at: nil) }
  scope :recent, -> { order(created_at: :desc).limit(20) }

  # ✅ HOTWIRE STREAM OVERWRITE
  # Prepend new alerts automatically onto your navbar feed target row container in real-time!
  after_create_commit do
    broadcast_prepend_to "global_notifications_#{recipient_id}",
                      target: "notifications_feed",
                      partial: "notifications/notification",
                      locals: { notification: self }
  end
end
