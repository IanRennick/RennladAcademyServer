# spec/models/wrong_answer_spec.rb
require "rails_helper"

RSpec.describe "Curriculum Distractor Analytics Engine", type: :model do
  let!(:b2_level) { Level.find_or_create_by!(name: "B2") { |l| l.initial_rating = 1200 } }
  let!(:puzzle) { Question.create!(kind: :open_cloze, level: b2_level, main: "This is an analytics sample sentence context.", answers: [ "test" ]) }

  describe "Data Integrity Guard Shields" do
    it "allows a valid incorrect answer tracking row to save cleanly" do
      wa = WrongAnswer.new(question: puzzle, answer_text: "wrong_guess", count: 1)
      expect(wa).to be_valid
    end

    it "blocks record creations missing required question identifiers or text blocks" do
      bad_wa = WrongAnswer.new(question: nil, answer_text: nil, count: 1)
      expect(bad_wa).not_to be_valid
    end

    it "strictly rejects negative values or zeros inside the frequency tracking counter" do
      broken_counter = WrongAnswer.new(question: puzzle, answer_text: "bad_try", count: 0)
      expect(broken_counter).not_to be_valid
    end

    it "strictly blocks duplicate text strings from being registered for the same target question" do
      WrongAnswer.create!(question: puzzle, answer_text: "common_trap", count: 2)

      duplicate = WrongAnswer.new(question: puzzle, answer_text: "common_trap", count: 1)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:answer_text]).to include("This specific distractor text string is already registered and tracked under this curriculum question entity")
    end
  end
end
