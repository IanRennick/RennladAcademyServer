# spec/models/user_history_spec.rb
require "rails_helper"

RSpec.describe "Student Performance History Engine", type: :model do
  let!(:b2_level) { Level.find_or_create_by!(name: "B2") { |l| l.initial_rating = 1200 } }
  let!(:student) { User.create!(username: "history_logger", email: "logger@test.com", password: "password123", role: :student) }
  let!(:puzzle) { Question.create!(kind: :open_cloze, level: b2_level, main: "This is a grammar core test sentence context.", answers: [ "test" ]) }

  describe "Data Integrity Guard Shields" do
    it "automatically handles review queue synchronization flags on a failed practice try" do
      history = UserHistory.create!(user: student, question: puzzle, first_attempt_correct: false)

      expect(history).to be_valid
      expect(history.needs_review).to eq(true) # The callback synchronized it perfectly!
    end

    it "blocks history records missing required parent identifier maps" do
      bad_log = UserHistory.new(user: nil, question: nil, first_attempt_correct: true)
      expect(bad_log).not_to be_valid
    end

    it "strictly intercepts attempts to clone identical historical entries for the same student-question pairing" do
      UserHistory.create!(user: student, question: puzzle, first_attempt_correct: true)

      duplicate = UserHistory.new(user: student, question: puzzle, first_attempt_correct: false)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:question_id]).to include("A practice metrics logging history event is already registered for this specific student-question node pair")
    end
  end
end
