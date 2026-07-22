# spec/models/question_spec.rb
# =========================================================================
# CENTRAL CURRICULUM QUESTION POOL MODEL MATRIX SPEC
# - Stress-tests fallback defaults, metric counter initializations, and tier inheritance
# - Validates strict compound type-subtype boundary mapping constraints
# - Asserts tag string normalization parser callbacks purge hash duplicates
# - Verifies case-insensitive floating multi-part scoring evaluation matrices
# =========================================================================
require "rails_helper"

RSpec.describe "Polymorphic Question Core Engine", type: :model do
  # --- Setup Shared Test Matrix Variables ---
  let!(:b2_level) { Level.find_or_create_by!(name: "B2") { |l| l.initial_rating = 1350 } }

  # =========================================================================
  # 1. DATABASE SCHEMA INITIALIZATION CALLBACKS TESTS
  # =========================================================================
  describe "Data Integrity Guard Shields" do
    it "automatically defaults metrics counters to zero and inherits ratings from CEFR parameters" do
      puzzle = Question.create!(kind: :open_cloze, level: b2_level, main: "He is capable * passing.", answers: [ "of" ])

      expect(puzzle.times_done).to eq(0)
      expect(puzzle.times_correct).to eq(0)
      expect(puzzle.rating).to eq(1350) # Inherited cleanly from B2 parameters!
    end

    # =========================================================================
    # 2. MANDATORY FIELDS PRESENCE CHECKS TESTS
    # =========================================================================
    it "blocks the creation of entries missing required prompts or correct answers arrays" do
      bad_puzzle = Question.new(kind: :open_cloze, main: nil, answers: [], level: b2_level)
      expect(bad_puzzle).not_to be_valid
    end

    # =========================================================================
    # 3. TYPE-SUBTYPE CATEGORY BOUNDARY SHIELDS TESTS
    # =========================================================================
    it "strictly rejects a subtype mapping configuration that breaks its kind distribution boundaries" do
      illegal_combo = Question.new(kind: :multiple_choice, subtype: :sc_conditional, main: "Broken row loop test.", answers: [ "test" ], level: b2_level)

      expect(illegal_combo).not_to be_valid
      expect(illegal_combo.errors[:subtype]).to include("is not a system-supported category for a Multiple choice puzzle type")
    end

    # =========================================================================
    # 4. GRAMMAR METADATA TAG NORMALIZATION PACKETS TESTS
    # =========================================================================
    it "automatically parses raw tag_list strings into fully sanitized relational tag model objects" do
      puzzle = Question.create!(kind: :word_formation, level: b2_level, main: "It was a * decision. (COLOUR)", answers: [ "colourful" ], tag_list: "  #Nouns, Adjectives!, nouns ")

      expect(puzzle.tags.pluck(:name)).to match_array([ "nouns", "adjectives" ])
    end
  end

  # =========================================================================
  # 5. MULTI-PART EVALUATION SYSTEM GRADING MATH TESTS
  # =========================================================================
  describe "#score_flat_submission (Evaluation Metrics System)" do
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
