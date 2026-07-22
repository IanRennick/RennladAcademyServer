# spec/models/message_spec.rb
# =========================================================================
# REAL-TIME COMMUNICATIONS SUITE MESSAGE MODEL SPEC
# - Stress-tests mandatory data attribute limits and validation constraints
# - Verifies security gates pass if a user belongs to a private participant list
# - Enforces authorization guard shields to block intruders from cross-posting
# =========================================================================
require "rails_helper"

RSpec.describe "Real-Time Message Engine", type: :model do
  # --- Setup Shared Test Matrix Variables ---
  let!(:sender) { User.create!(username: "message_author", email: "author@chat.com", password: "password123", role: :student) }
  let!(:outsider) { User.create!(username: "room_hacker", email: "hacker@chat.com", password: "password123", role: :student) }

  let!(:public_channel) { Room.create!(name: "general-study-lounge", is_private: false) }
  let!(:private_channel) { Room.create!(name: "secure-dms-hub", is_private: true) }

  # =========================================================================
  # 1. TEXT PARAMETER PERIMETER BOUNDS TESTS
  # =========================================================================
  describe "Data Integrity Guard & Security Shield" do
    it "blocks the creation of entries missing structural text body parameters" do
      bad_msg = Message.new(user: sender, room: public_channel, body: nil)
      expect(bad_msg).not_to be_valid
    end

    # =========================================================================
    # 2. PARTICIPANTS WHITELIST VERIFICATION TESTS
    # =========================================================================
    it "strictly allows messages when the student is an authorized participant in a private room" do
      # Add sender user profile record to the participant matrix whitelist loop
      Participant.create!(user: sender, room: private_channel)

      msg = Message.new(user: sender, room: private_channel, body: "Valid internal credentials verification.")
      expect(msg).to be_valid
    end

    # =========================================================================
    # 3. ANTI-INTRUSION SECURE CHANNEL BLOCKS TESTS
    # =========================================================================
    it "strictly blocks message creation if a non-participant attempts to write into a secure private chat thread" do
      # No participant row is seeded for 'outsider', triggering an immediate abort throw gate
      illegal_msg = Message.new(user: outsider, room: private_channel, body: "Malicious injection packet bypass try.")

      expect(illegal_msg).not_to be_valid
    end
  end
end
