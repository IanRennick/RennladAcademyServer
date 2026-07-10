class Level < ApplicationRecord
  # If a level record is ever dropped, protect questions by setting their reference to nil
  has_many :questions, dependent: :nullify

  # Enforce strict uppercase validation structures (e.g. Always "B2", never "b2")
  validates :name, presence: true, uniqueness: { case_sensitive: false }
  before_save { self.name = name.upcase.strip }
end
