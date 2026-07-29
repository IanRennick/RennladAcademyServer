# app/models/flag.rb
class Flag < ApplicationRecord
  belongs_to :user
  belongs_to :commentable, polymorphic: true

  # Enum states for rapid administrative filtering dashboard pipelines
  enum :report_type, { typo: 0, bad_cloze: 1, structural_bug: 2, offensive_comment: 3 }
  enum :status, { open: 0, under_review: 1, resolved: 2, ignored: 3 }

  validates :report_type, presence: true
end
