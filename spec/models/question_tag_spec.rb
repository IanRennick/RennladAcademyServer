# spec/models/question_tag_spec.rb
# =========================================================================
# SYSTEM CURRICULUM POOL JOIN-MODEL MAPPING SPEC
# - Stress-tests relational mapping pairs linking tags directly to puzzles
# - Asserts required identity foreign keys enforce correct record presence
# - Enforces unique index limits to completely block duplicate metadata logs
# =========================================================================
require "rails_helper"

RSpec.describe "Question-to-Tag Mapping Matrix", type: :model do
  # --- Setup Shared Test Matrix Variables ---
  let!(:b2_level) { Level.find_or_create_by!(name: "B2") { |l| l.initial_rating = 1200 } }
  let!(:puzzle) { Question.create!(kind: :open_cloze, level: b2_level, main: "This is a grammar sample sentence context.", answers: [ "test" ]) }
  let!(:grammar_tag) { Tag.create!(name: "inversions") }

  # =========================================================================
  # 1. CLEAN RECOGNITION INTERACTION RELATIONSHIPS TESTS
  # =========================================================================
  describe "Data Integrity Guard Shields" do
    it "allows a valid question and tag pair mapping to register cleanly" do
      mapping = QuestionTag.new(question: puzzle, tag: grammar_tag)
      expect(mapping).to be_valid
    end

    # =========================================================================
    # 2. REQUIRED SCHEMA ATTRIBUTE CONTROLS TESTS
    # =========================================================================
    it "blocks entries missing mandatory parent identifier keys" do
      bad_mapping = QuestionTag.new(question: nil, tag: nil)
      expect(bad_mapping).not_to be_valid
    end

    # =========================================================================
    # 3. COMPOUND COLUMN KEY COLLISION SHIELDS TESTS
    # =========================================================================
    it "strictly blocks duplicate row links for the same question and tag pair allocation" do
      QuestionTag.create!(question: puzzle, tag: grammar_tag)

      duplicate = QuestionTag.new(question: puzzle, tag: grammar_tag)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:tag_id]).to include("This specific structural tag string is already associated with the targeted curriculum question profile")
    end
  end
end
