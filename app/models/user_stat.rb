class UserStat < ApplicationRecord
  belongs_to :user

  # Safeguard parameters to prevent bad data insertion
  validates :stat_type, inclusion: { in: %w[kind subtype] }
  validates :stat_key, :times_done, :times_correct, presence: true

  # ✅ Add this callback to fix the find_or_create_by validation crash
  before_validation :set_defaults, on: :create


  private

  def set_defaults
    self.times_done ||= 0
    self.times_correct ||= 0
  end
end
