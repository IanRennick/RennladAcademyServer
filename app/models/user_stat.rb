class UserStat < ApplicationRecord
  belongs_to :user

  # Safeguard parameters to prevent bad data insertion
  validates :stat_type, inclusion: { in: %w[kind subtype] }
  validates :stat_key, :times_done, :times_correct, presence: true
end
