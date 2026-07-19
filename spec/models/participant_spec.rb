# spec/models/participant_spec.rb
require "rails_helper"

RSpec.describe "Secure Participant Cohort Engine", type: :model do
  let!(:student) { User.create!(username: "cohort_member", email: "cohort@test.com", password: "password123", role: :student) }
  let!(:secure_room) { Room.create!(name: "private-study-dms", is_private: true) }

  describe "Data Integrity Guard Shields" do
    it "allows a user to be added as a valid participant to a room cleanly" do
      entry = Participant.new(user: student, room: secure_room)
      expect(entry).to be_valid
    end

    it "blocks the creation of entries missing required model mapping id associations" do
      bad_entry = Participant.new(user: nil, room: nil)
      expect(bad_entry).not_to be_valid
    end

    it "strictly rejects duplicate database row allocations for the same student-room mapping pair" do
      Participant.create!(user: student, room: secure_room)

      duplicate_entry = Participant.new(user: student, room: secure_room)
      expect(duplicate_entry).not_to be_valid
      expect(duplicate_entry.errors[:user_id]).to include("Student account entity is already assigned as an active participant inside this targeted room channel")
    end
  end
end
