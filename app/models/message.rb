class Message < ApplicationRecord
  # Create associations with User and chatroom
  belongs_to :user
  belongs_to :room

  # Add new message to room without needing to refresh page
  after_create_commit { broadcast_append_to self.room }
end
