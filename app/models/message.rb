class Message < ApplicationRecord
  # Create associations with User and chatroom
  belongs_to :user
  belongs_to :room

  # Add new message to room without needing to refresh page
  after_create_commit { broadcast_append_to self.room }

  before_create :confirm_participant



  def confirm_participant
    return unless room.is_private
    is_participant = Participant.where(user_id: self.user.id, room_id: self.room.id).first
    throw :abort unless is_participant
  end
end
