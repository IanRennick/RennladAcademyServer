class Room < ApplicationRecord
  # Make sure the room name is unique
  validates_uniqueness_of :name

  # Add new user to list of users without needing to refresh page
  after_create_commit { broadcast_append_to "rooms" }

  # Helper for when we only want to access public rooms
  scope :public_rooms, -> { where(is_private: false) }

  # Associate with Messages
  has_many :messages
end
