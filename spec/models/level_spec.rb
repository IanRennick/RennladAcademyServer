# spec/models/level_spec.rb
# =========================================================================
# CEFR LEVEL HIERARCHY MODEL MATRIX SPEC
# - Stress-tests automated text normalization callbacks and uppercase string forcing
# - Verifies structural validation shields block non-standard character codes
# - Enforces strict unique case-insensitive constraints across database slots
# =========================================================================
require "rails_helper"

RSpec.describe "CEFR Level Hierarchy Engine", type: :model do
  # =========================================================================
  # 1. AUTOMATED DATA NORMALIZATION CALLBACKS TESTS
  # =========================================================================
  describe "Data Integrity Guard Shields" do
    it "automatically cleanses trailing whitespace strings and forces uppercase conversions on save" do
      lvl = Level.create!(name: "  c1  ")
      expect(lvl.name).to eq("C1")
    end

    # =========================================================================
    # 2. CHARACTER SCHEMA SPECIFICATION BOUNDARIES TESTS
    # =========================================================================
    it "blocks the creation of levels containing non-CEFR standard character formats" do
      bad_lvl = Level.new(name: "Z9")
      expect(bad_lvl).not_to be_valid
      expect(bad_lvl.errors[:name]).to include("must represent a valid system-supported CEFR code format profile string (e.g. B2, C1)")
    end

    # =========================================================================
    # 3. GLOBAL UNIQUENESS COLLISION GATES TESTS
    # =========================================================================
    it "enforces full unique case-insensitive constraints across all database columns" do
      Level.create!(name: "B2")
      duplicate = Level.new(name: "b2")
      expect(duplicate).not_to be_valid
    end
  end
end
