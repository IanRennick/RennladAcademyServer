require "rails_helper"

RSpec.describe "Achievement Badge System Engine", type: :model do
  let!(:student) { User.create!(username: "milestone_runner", email: "runner@badge.com", password: "password123") }

  # Seed our master platform achievement milestones
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

  describe "#check_and_award_achievements!" do
    context "when a student is practicing questions" do
      it "automatically unlocks badges and triggers navbar alerts only when crossing thresholds" do
        expect(student.badges.count).to eq(0)

        # 1. Simulate answering their first puzzle
        student.user_stats.create!(stat_type: "kind", stat_key: 0, times_done: 1, times_correct: 1, rating: 1200)

        expect {
          student.check_and_award_achievements!
        }.to change(student.badges, :count).by(1)

        # Verify exact badge identity ownership and automated notification trigger strings
        expect(student.badges.first).to eq(bronze_badge)
        expect(student.notifications.unread.count).to eq(1)
        expect(student.notifications.last.params["message"]).to include("unlocked the 'Grammar Cadet' achievement medal!")

        # 2. Simulate subsequent progress that DOES NOT cross the next high threshold yet (e.g. total 10)
        student.user_stats.first.update!(times_done: 10)

        expect {
          student.check_and_award_achievements!
        }.not_to change(student.badges, :count)

        # 3. Simulate crossing the major gold medal threshold milestone line (e.g. total 52)
        student.user_stats.first.update!(times_done: 52)

        expect {
          student.check_and_award_achievements!
        }.to change(student.badges, :count).by(1)

        expect(student.badges.pluck(:name)).to include("Puzzle Veteran")
        expect(student.notifications.unread.count).to eq(2)
      end
    end
  end
end
