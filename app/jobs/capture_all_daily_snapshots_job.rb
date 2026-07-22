# app/jobs/capture_all_daily_snapshots_job.rb
# =========================================================================
# NIGHTLY AUTOMATED TELEMETRY SNAPSHOT COMPILATION JOB
# - Iterates through all registered platform accounts to compile daily charts
# - Utilizes find_each memory batching to prevent production RAM exhaustion
# - Executed off-peak via Solid Queue's low-priority background worker channels
# =========================================================================
class CaptureAllDailySnapshotsJob < ApplicationJob
  # PERFORMANCE OPTIMIZATION: Shifted to the low-priority queue channel
  # to safeguard default and high-speed execution lines from background batch bloat
  queue_as :low_priority

  # Primary asynchronous worker thread entry point
  def perform
    Rails.logger.info "⏱️ [Nightly Cron] Commencing automated student Elo snapshot capture..."

    # Securely queries user records in isolated blocks of 1000
    User.find_each do |user|
      user.capture_daily_snapshot
    rescue => e
      Rails.logger.error "❌ [Snapshot Failure] Failed to record statistics for User ##{user.id}: #{e.message}"
      next # Proceed cleanly to the next user row if a single profile corrupts
    end

    Rails.logger.info "⏱️ [Nightly Cron] Global student performance snapshot mapping complete!"
  end
end
