class UserBadge < ApplicationRecord
  belongs_to :user
  belongs_to :badge

  # Standard Rails level guard check matching our database uniqueness rule
  validates :badge_id, uniqueness: { scope: :user_id, message: "Achievement milestone already earned!" }
end
