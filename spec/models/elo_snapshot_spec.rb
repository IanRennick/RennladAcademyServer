require "rails_helper"

RSpec.describe EloSnapshot, type: :model do
  describe "Composite Unique DB Index" do
    let(:user) { User.create!(username: "snapshot_student", email: "snap@test.com", password: "password123") }

    it "blocks duplicate logs and safely updates via upsert loops including category breakdowns" do
      # Seed a dummy category rating record for the user
      user.user_stats.create!(stat_type: "kind", stat_key: 0, times_done: 1, times_correct: 1, rating: 1250) # multiple_choice

      # Initial snapshot creation
      user.capture_daily_snapshot
      expect(user.elo_snapshots.count).to eq(1)

      # ✅ VERIFY CATEGORY RECORD DATA INTEGRITY
      first_snapshot = user.elo_snapshots.find_by(recorded_on: Date.current)
      expect(first_snapshot.category_ratings["multiple_choice"]).to eq(1250)

      # Update rating and fire again on the exact same unique calendar date
      user.update!(rating: 1250)

      expect {
        user.capture_daily_snapshot
      }.not_to change(user.elo_snapshots, :count)

      expect(user.elo_snapshots.find_by(recorded_on: Date.current).rating).to eq(1250)
    end
  end
end
