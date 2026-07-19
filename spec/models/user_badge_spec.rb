# spec/models/user_badge_spec.rb
require "rails_helper"

RSpec.describe "Gamification Badge Ownership Matrix", type: :model do
  let!(:student) { User.create!(username: "medal_collector", email: "collector@badge.com", password: "password123", role: :student) }
  let!(:achievement) do
    Badge.create!(
      name: "Grammar Cadet",
      description: "Answer your very first question puzzle successfully.",
      milestone_type: "total_questions",
      milestone_threshold: 1
    )
  end

  describe "Data Integrity Guard Shields" do
    it "allows a valid student and badge association to register cleanly" do
      ownership = UserBadge.new(user: student, badge: achievement)
      expect(ownership).to be_valid
    end

    it "blocks record creations missing mandatory parent identifiers" do
      bad_ownership = UserBadge.new(user: nil, badge: nil)
      expect(bad_ownership).not_to be_valid
    end

    it "strictly blocks a student from earning the exact same milestone badge multiple times" do
      UserBadge.create!(user: student, badge: achievement)

      duplicate = UserBadge.new(user: student, badge: achievement)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:badge_id]).to include("Achievement milestone already earned!")
    end
  end
end
