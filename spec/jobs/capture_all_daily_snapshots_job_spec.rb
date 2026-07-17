require "rails_helper"

RSpec.describe CaptureAllDailySnapshotsJob, type: :job do
  describe "#perform" do
    let!(:student_one) { User.create!(username: "student_a", email: "one@test.com", password: "password123", rating: 1300) }
    let!(:student_two) { User.create!(username: "student_b", email: "two@test.com", password: "password123", rating: 1450) }

    it "safely runs through all enrolled students and compiles daily rating records" do
      expect {
        CaptureAllDailySnapshotsJob.perform_now
      }.to change(EloSnapshot, :count).by(2)

      expect(student_one.elo_snapshots.last.rating).to eq(1300)
      expect(student_two.elo_snapshots.last.rating).to eq(1450)
    end
  end
end
