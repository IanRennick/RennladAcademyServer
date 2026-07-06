class UserStat < ApplicationRecord
  # Make sure default values are stored as 0 and not nil
  before_validation :set_defaults, on: :create

  # Validate parameters to prevent bad data insertion
  validates :stat_type, inclusion: { in: %w[kind subtype] }
  validates :stat_key, :times_done, :times_correct, presence: true
  validates :stat_key, uniqueness: { scope: [ :user_id, :stat_type ] }

  # Association with user
  belongs_to :user


  private

  # Set default values
  def set_defaults
    self.times_done ||= 0
    self.times_correct ||= 0
  end
end
