class UserStat < ApplicationRecord
  # Association with user
  belongs_to :user

  # Safeguard parameters to prevent bad data insertion
  validates :stat_type, inclusion: { in: %w[kind subtype] }
  validates :stat_key, :times_done, :times_correct, :rating, presence: true
  validates :stat_key, uniqueness: { scope: [ :user_id, :stat_type ] }
end
