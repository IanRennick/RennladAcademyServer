# spec/models/room_spec.rb
require "rails_helper"

RSpec.describe "Real-Time Room Channel Engine", type: :model do
  let!(:user_a) { User.create!(username: "chat_partner_a", email: "partner_a@chat.com", password: "password123", role: :student) }
  let!(:user_b) { User.create!(username: "chat_partner_b", email: "partner_b@chat.com", password: "password123", role: :student) }
  let!(:outsider) { User.create!(username: "room_lurker", email: "lurker@chat.com", password: "password123", role: :student) }

  describe "Private Factory & Participant Helpers" do
    it "creates a private room and instantiates participant join table rows for all passed users" do
      private_room = Room.create_private_room([ user_a, user_b ], "chat_partner_a-chat_partner_b")

      expect(private_room.is_private).to eq(true)
      expect(private_room.participant?(user_a)).to eq(true)
      expect(private_room.participant?(user_b)).to eq(true)
      expect(private_room.participant?(outsider)).to eq(false)
    end
  end

  describe "Data Integrity Guard Shields" do
    it "blocks room creations that are missing explicit channel name tags" do
      bad_room = Room.new(name: nil)
      expect(bad_room).not_to be_valid
    end

    it "enforces full unique case-insensitive constraints across all channel rows" do
      Room.create!(name: "ielts-vocabulary")
      duplicate = Room.new(name: "IELTS-VOCABULARY")
      expect(duplicate).not_to be_valid
    end
  end
end
