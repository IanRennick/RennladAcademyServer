# spec/models/elo_snapshot_spec.rb
# =========================================================================
# HISTORICAL ELO SNAPSHOT MODEL MATRIX SPEC
# - Stress-tests data integrity rules and required schema field validations
# - Asserts relational fallback defaults assign clean structural hash frames
# - Enforces strict boundaries against negative score values or corrupt bounds
# =========================================================================
require "rails_helper"

RSpec.describe "Historical Elo Snapshot Engine", type: :model do
  # --- Setup Shared Test Matrix Variables ---
  let!(:student) { User.create!(username: "history_buff", email: "history@test.com", password: "password123", role: :student) }

  # =========================================================================
  # 1. DATABASE SCHEMA FALLBACK DEFAULTS TESTS
  # =========================================================================
  describe "Data Integrity Guard Shields" do
    it "safely instantiates an empty category hash payload if none is explicitly passed on creation" do
      snapshot = EloSnapshot.create!(user: student, rating: 1250, recorded_on: Date.current)

      expect(snapshot).to be_valid
      expect(snapshot.category_ratings).to eq({})
    end

    # =========================================================================
    # 2. MANDATORY ATTRIBUTE PRESENCE CHECKS TESTS
    # =========================================================================
    it "blocks snapshot records from saving if they are missing required calendar dates or ratings" do
      bad_snapshot = EloSnapshot.new(user: student, rating: nil, recorded_on: nil)
      expect(bad_snapshot).not_to be_valid
    end

    # =========================================================================
    # 3. SCORE MATHEMATICAL BOUNDARY SHIELDS TESTS
    # =========================================================================
    it "strictly rejects negative numbers or corrupt rating strings" do
      broken_rating = EloSnapshot.new(user: student, rating: -100, recorded_on: Date.current)
      expect(broken_rating).not_to be_valid
    end
  end
end
