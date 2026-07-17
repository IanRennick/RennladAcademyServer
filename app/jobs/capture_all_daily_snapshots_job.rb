# app/jobs/capture_all_daily_snapshots_job.rb
class CaptureAllDailySnapshotsJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "⏱️ [Nightly Cron] Commencing automated student Elo snapshot capture..."

    # find_each safely batches students in blocks of 1000 to protect server memory RAM
    User.find_each do |user|
      user.capture_daily_snapshot
    end

    Rails.logger.info "⏱️ [Nightly Cron] Global student performance snapshot mapping complete!"
  end
end
