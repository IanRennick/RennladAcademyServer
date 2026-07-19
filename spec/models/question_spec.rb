# spec/models/question_spec.rb
require "rails_helper"

RSpec.describe "Polymorphic Question Core Engine", type: :model do
  let!(:b2_level) { Level.find_or_create_by!(name: "B2") { |l| l.initial_rating = 1350 } }

  describe "Data Integrity Guard Shields" do
    it "automatically defaults metrics counters to zero and inherits ratings from CEFR parameters" do
      puzzle = Question.create!(kind: :open_cloze, level: b2_level, main: "He is capable * passing.", answers: [ "of" ])

      expect(puzzle.times_done).to eq(0)
      expect(puzzle.times_correct).to eq(0)
      expect(puzzle.rating).to eq(1350) # Inherited cleanly from B2 parameters!
    end

    it "blocks the creation of entries missing required prompts or correct answers arrays" do
      bad_puzzle = Question.new(kind: :open_cloze, main: nil, answers: [], level: b2_level)
      expect(bad_puzzle).not_to be_valid
    end

    it "strictly rejects a subtype mapping configuration that breaks its kind distribution boundaries" do
      illegal_combo = Question.new(kind: :multiple_choice, subtype: :sc_conditional, main: "Broken row loop test.", answers: [ "test" ], level: b2_level)

      expect(illegal_combo).not_to be_valid
      expect(illegal_combo.errors[:subtype]).to include("is not a system-supported category for a Multiple choice puzzle type")
    end

    it "automatically parses raw tag_list strings into fully sanitized relational tag model objects" do
      # ✅ FIXED: Added level: b2_level to satisfy database constraints
      puzzle = Question.create!(kind: :word_formation, level: b2_level, main: "It was a * decision. (COLOUR)", answers: [ "colourful" ], tag_list: "  #Nouns, Adjectives!, nouns ")

      expect(puzzle.tags.pluck(:name)).to match_array([ "nouns", "adjectives" ])
    end
  end

  describe "#score_flat_submission (Evaluation Metrics System)" do
    # FIXED: Added level: b2_level to satisfy database constraints
    let!(:puzzle) { Question.create!(kind: :open_cloze, level: b2_level, main: "Test prompt.", answers: [ "won", "had won" ]) }

    it "awards a perfect 1.0 score when string metrics match any item inside the answer matrix case-insensitively" do
      expect(puzzle.score_flat_submission("  WON  ")).to eq(1.0)
      expect(puzzle.score_flat_submission("had won")).to eq(1.0)
    end

    it "returns a flat 0.0 score when answers miss the whitelisted answer array criteria entirely" do
      expect(puzzle.score_flat_submission("lost")).to eq(0.0)
      expect(puzzle.score_flat_submission(nil)).to eq(0.0)
    end
  end
end
