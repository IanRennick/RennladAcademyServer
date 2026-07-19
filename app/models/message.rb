# app/models/message.rb
# =========================================================================
# REAL-TIME COMMUNICATIONS SUITE MESSAGE BALLOON MODEL
# - Coordinates ActionCable real-time WebSocket screen appends
# - Coordinates polymorphic notification dispatch maps for direct and public feeds
# - Enforces strict chatroom participant security isolation gates
# =========================================================================
class Message < ApplicationRecord
  # --- Associations ---
  belongs_to :user
  belongs_to :room

  # --- Validations & Security Filters ---
  validates :body, presence: true
  validate :confirm_participant_security_gate

  # --- Hotwire Turbo Broadcast Hooks ---
  # Broadcasts the new message row layout downstream to everyone connected to the room thread in real time
  after_create_commit { broadcast_append_to self.room }
  after_create_commit :notify_recipients

  private

  # OPTIMIZATION GUARD: Blocks malicious attempts to inject text lines into private rooms where the user is not a participant
  def confirm_participant_security_gate
    return unless room&.is_private?

    is_valid_participant = Participant.where(user_id: user_id, room_id: room_id).exists?
    unless is_valid_participant
      errors.add(:base, "Unauthorized: Student profile is not an assigned participant within this private direct chat room channel.")
    end
  end

  # Scans current active user states across the cluster to dispatch target notification records
  def notify_recipients
    if room.is_private?
      # A. PRIVATE DIRECT CHATS: Notify the conversation partner row instantly
      room.participants.where.not(user_id: user_id).each do |participant|
        Notification.create!(
          recipient_id: participant.user_id,
          actor: user,
          event_type: "new_chat_message",
          params: {
            "message" => "sent you a direct message",
            "text_snippet" => body.to_s.truncate(35),
            "url" => "/rooms/#{room.id}"
          }
        )
      end
    else
      # B. PUBLIC DISCUSSION CHANNELS: Notify active users on the server (skipping yourself)
      # Limits queries strictly to online/away users to protect the database from ballooning bloat
      User.where(status: [ :online, :away ]).where.not(id: user_id).each do |active_user|
        Notification.create!(
          recipient: active_user,
          actor: user,
          event_type: "public_chat_message",
          params: {
            "message" => "posted in public chat channel ##{room.name}",
            "text_snippet" => body.to_s.truncate(35),
            "url" => "/rooms/#{room.id}"
          }
        )
      end
    end
  end
end
