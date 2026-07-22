# spec/jobs/capture_all_daily_snapshots_job_spec.rb
require "rails_helper"

RSpec.describe CaptureAllDailySnapshotsJob, type: :job do
  include ActiveJob::TestHelper

  # --- Setup Shared Test Matrix Variables ---
  let!(:student_a) { User.create!(username: "chart_student_a", email: "student_a@test.com", password: "password123", rating: 1250) }
  let!(:student_b) { User.create!(username: "chart_student_b", email: "student_b@test.com", password: "password123", rating: 1300) }

  describe "#perform Nightly Iteration Loops" do
    it "successfully queues up on the low_priority lane and fires user snapshot creation methods" do
      # Assert the job initializes inside the correct Solid Queue priority tracking bracket
      expect(CaptureAllDailySnapshotsJob.new.queue_name).to eq("low_priority")

      expect {
        CaptureAllDailySnapshotsJob.perform_now
      }.to change(EloSnapshot, :count).by(2)

      # Verify individual student record row mappings match active data parameters exactly
      expect(student_a.elo_snapshots.find_by(recorded_on: Date.current).rating).to eq(1250)
      expect(student_b.elo_snapshots.find_by(recorded_on: Date.current).rating).to eq(1300)
    end
  end
end
