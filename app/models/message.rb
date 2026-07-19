class Message < ApplicationRecord
  # Create associations with User and chatroom
  belongs_to :user
  belongs_to :room


  # Add new message to room without needing to refresh page
  after_create_commit { broadcast_append_to self.room }

  # ✅ NEW SPRINT TRIGGER: Fire real-time notification alerts across the platform
  after_create_commit :notify_recipients

  before_create :confirm_participant



  def confirm_participant
    return unless room.is_private
    is_participant = Participant.where(user_id: self.user.id, room_id: self.room.id).first
    throw :abort unless is_participant
  end



   private

  def notify_recipients
    if room.is_private?
      # A. PRIVATE ROOM DIRECT CHATS: Notify the other explicit participant row instantly
      # Pull all participants in this private room, skipping yourself
      room.participants.where.not(user_id: self.user_id).each do |participant|
        Notification.create!(
          recipient_id: participant.user_id,
          actor: self.user,
          event_type: "new_chat_message",
          params: {
            "message" => "sent you a direct message",
            "text_snippet" => self.body.to_s.truncate(35),
            "url" => "/rooms/#{room.id}" # Deep-links straight to the active conversation panel
          }
        )
      end
    else
      # B. PUBLIC CHAT ROOMS: Notify any active user on the server (skipping yourself)
      # Optimization guard rails: only notify users marked as 'online' or 'away' to prevent database bloating
      User.where(status: [ :online, :away ]).where.not(id: self.user_id).each do |active_user|
        Notification.create!(
          recipient: active_user,
          actor: self.user,
          event_type: "public_chat_message",
          params: {
            "message" => "posted in public chat channel ##{room.name}",
            "text_snippet" => self.body.to_s.truncate(35),
            "url" => "/rooms/#{room.id}"
          }
        )
      end
    end
  end
end
