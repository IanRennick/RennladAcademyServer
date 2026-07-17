require "rails_helper"

RSpec.describe EloSnapshot, type: :model do
  describe "Composite Unique DB Index" do
    let(:user) { User.create!(username: "snapshot_student", email: "snap@test.com", password: "password123") }

    it "blocks duplicate logs and safely updates via upsert loop definitions" do
      # Initial creation
      user.capture_daily_snapshot
      expect(user.elo_snapshots.count).to eq(1)

      # Update rating and fire again on the exact same unique calendar date
      user.update!(rating: 1250)

      expect {
        user.capture_daily_snapshot
      }.not_to change(user.elo_snapshots, :count)

      expect(user.elo_snapshots.find_by(recorded_on: Date.current).rating).to eq(1250)
    end
  end
end
