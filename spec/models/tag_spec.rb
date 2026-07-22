# spec/models/tag_spec.rb
# =========================================================================
# GRAMMATICAL TAG DIRECTORY MODEL MATRIX SPEC
# - Stress-tests automated text normalization callbacks and punctuation stripping
# - Asserts required character parameter validations prevent empty records
# - Enforces strict unique case-insensitive constraints across database columns
# =========================================================================
require "rails_helper"

RSpec.describe "Grammatical Tag Directory Engine", type: :model do
  # =========================================================================
  # 1. AUTOMATED NORMALIZATION CALLBACKS TESTS
  # =========================================================================
  describe "Data Integrity Guard Shields" do
    it "automatically cleanses whitespaces, downcases characters, and strips raw hashtags before validation" do
      tag = Tag.create!(name: "  #Conditionals!  ")
      expect(tag.name).to eq("conditionals")
    end

    # =========================================================================
    # 2. SCHEMA ATTRIBUTE BOUNDARY CONTROLS TESTS
    # =========================================================================
    it "blocks the creation of tags that reduce to a completely empty name string" do
      bad_tag = Tag.new(name: "!!!")
      expect(bad_tag).not_to be_valid
      expect(bad_tag.errors[:name]).to include("can't be blank")
    end

    # =========================================================================
    # 3. GLOBAL COLUMN UNIQUE CONSTRAINT SHIELDS TESTS
    # =========================================================================
    it "enforces strict unique case-insensitive constraints across all database columns" do
      Tag.create!(name: "inversions")
      duplicate = Tag.new(name: "Inversions")
      expect(duplicate).not_to be_valid
    end
  end
end
