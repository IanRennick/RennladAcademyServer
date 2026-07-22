# spec/models/badge_spec.rb
# =========================================================================
# SYSTEM GAMIFICATION ACHIEVEMENT ENGINE SPEC
# - Stress-tests automated achievement award routines and user badge linking
# - Verifies live system notification payloads dispatched upon unlocking milestones
# - Enforces data integrity shields protecting badge naming uniqueness limits
# =========================================================================
require "rails_helper"

RSpec.describe "Achievement Badge System Engine", type: :model do
  # --- Setup Shared Test Matrix Variables ---
  let!(:student) { User.create!(username: "milestone_runner", email: "runner@badge.com", password: "password123", role: :student) }

  # Seed system-supported master achievements matching valid whitelist tokens
  let!(:bronze_badge) do
    Badge.create!(
      name: "Grammar Cadet",
      description: "Answer your very first question puzzle successfully.",
      milestone_type: "total_questions",
      milestone_threshold: 1
    )
  end

  let!(:gold_badge) do
    Badge.create!(
      name: "Puzzle Veteran",
      description: "Complete 50 vocabulary or grammar puzzles.",
      milestone_type: "total_questions",
      milestone_threshold: 50
    )
  end

  # =========================================================================
  # 1. AUTOMATED MILESTONE AWARD LIFECYCLE TESTS
  # =========================================================================
  describe "#check_and_award_achievements!" do
    context "when a student is practicing questions" do
      it "automatically unlocks badges and triggers navbar alerts only when crossing thresholds" do
        expect(student.badges.count).to eq(0)

        # 1. Simulate answering their very first puzzle row entry
        student.user_stats.create!(stat_type: "kind", stat_key: 0, times_done: 1, times_correct: 1, rating: 1200)

        expect {
          student.check_and_award_achievements!
        }.to change(student.badges, :count).by(1)

        # Verify exact badge identity ownership and automated notification trigger strings
        expect(student.badges.first).to eq(bronze_badge)
        expect(student.notifications.unread.count).to eq(1)
        expect(student.notifications.last.params["message"]).to include("unlocked the 'Grammar Cadet' achievement medal!")

        # 2. Simulate subsequent progress that DOES NOT cross the next high threshold yet (e.g., total 10)
        student.user_stats.first.update!(times_done: 10)

        expect {
          student.check_and_award_achievements!
        }.not_to change(student.badges, :count)

        # 3. Simulate crossing the major gold medal threshold milestone line (e.g., total 52)
        student.user_stats.first.update!(times_done: 52)

        expect {
          student.check_and_award_achievements!
        }.to change(student.badges, :count).by(1)

        expect(student.badges.pluck(:name)).to include("Puzzle Veteran")
        expect(student.notifications.unread.count).to eq(2)
      end
    end
  end

  # =========================================================================
  # 2. DATA INTEGRITY & VALIDATION GUARD SHIELDS TESTS
  # =========================================================================
  describe "Authoritative Data Validation Shield" do
    it "blocks badges missing mandatory name, type, or threshold keys" do
      bad_badge = Badge.new(name: nil, milestone_type: "total_questions", milestone_threshold: nil)
      expect(bad_badge).not_to be_valid
    end

    it "strictly rejects duplicate name allocations to prevent registry collisions" do
      duplicate_badge = Badge.new(
        name: "Grammar Cadet", # Collision with let! block up top
        description: "An copycat record profile entry try.",
        milestone_type: "total_questions",
        milestone_threshold: 5
      )
      expect(duplicate_badge).not_to be_valid
    end

    it "strictly rejects unsupported achievement milestone type tokens" do
      illegal_badge = Badge.new(name: "Hacker Medal", milestone_type: "hacked_the_server", milestone_threshold: 5)
      expect(illegal_badge).not_to be_valid
      expect(illegal_badge.errors[:milestone_type]).to include("hacked_the_server is not a supported, functional milestone execution route")
    end

    it "enforces thresholds to be positive, whole integer numbers" do
      broken_threshold = Badge.new(name: "Micro Medal", milestone_type: "total_questions", milestone_threshold: 0)
      expect(broken_threshold).not_to be_valid
    end
  end
end
