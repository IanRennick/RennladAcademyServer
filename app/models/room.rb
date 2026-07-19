# app/models/room.rb
# =========================================================================
# REAL-TIME COMMUNICATIONS SUITE ROOM CHANNEL MODEL
# - Houses public topic channels and isolated secure private direct chats
# - Coordinates real-time Turbo ActionCable stream broadcasts to side panels
# =========================================================================
class Room < ApplicationRecord
  # --- Associations ---
  has_many :messages, dependent: :destroy
  has_many :participants, dependent: :destroy

  # --- Validations ---
  validates :name, presence: true, uniqueness: { case_sensitive: false }

  # --- Scopes Matrix ---
  # Helper for when we only want to access public discussion streams
  scope :public_rooms, -> { where(is_private: false) }

  # --- Hotwire Turbo Broadcast Hooks ---
  # Dynamically appends the fresh channel row layout to the left panel grid on create
  after_create_commit :broadcast_if_public

  # --- Class Level Factory Constructors ---
  # Generates a private direct message room, mapping active student profiles instantly
  def self.create_private_room(users, room_name)
    single_room = Room.create(name: room_name, is_private: true)

    users.each do |user|
      Participant.create(user_id: user.id, room_id: single_room.id)
    end

    single_room
  end

  # --- Instance Level Helper Queries ---
  # Self-contained instance method checks if a user is an active participant in this room
  def participant?(user)
    participants.where(user: user).exists?
  end

  private

  # Optimization filter ensuring that hidden direct message spaces skip public channel list broadcasts
  def broadcast_if_public
    broadcast_append_to "rooms" unless is_private?
  end
end
