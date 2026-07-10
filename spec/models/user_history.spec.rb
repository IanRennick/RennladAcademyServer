require 'rails_helper'

RSpec.describe UserHistory, type: :model do
  # Test associations
  describe "associations" do
    it { should belong_to(:user) }
    it { should belong_to(:question) }
  end

  # Test database security index guard
  describe "validations" do
    context "scoped uniqueness index" do
      # Set up an initial baseline record in the test database
      subject {
        UserHistory.new(
          user_id: 1,
          question_id: 1,
          first_attempt_correct: true,
          needs_review: false
        )
      }

      # Assert that a user cannot have two history entries for the exact same question
      it { should validate_uniqueness_of(:question_id).scoped_to(:user_id) }
    end
  end
end
