# spec/models/user_tag_stat_spec.rb
# =========================================================================
# GRAMMAR TAG METRICS CACHE MODEL SPEC
# - Stress-tests relational ownership vectors linking caches to accounts
# - Asserts JSON metadata fallback schemas instantiate empty configurations
# - Enforces strict uniqueness locks preventing duplicate dashboard cache slots
# =========================================================================
require "rails_helper"

RSpec.describe UserTagStat, type: :model do
  # --- Setup Shared Test Matrix Variables ---
  let!(:student) { User.create!(username: "analytics_genius", email: "stats@test.com", password: "password123", role: :student) }

  # =========================================================================
  # 1. CORE ACTIVE RECORD ASSOCIATIONS TESTS
  # =========================================================================
  describe "Associations Matrix" do
    it { should belong_to(:user) }
  end

  # =========================================================================
  # 2. LIFECYCLE CALLBACK INITIALIZATION TESTS
  # =========================================================================
  describe "Data Integrity Guard Shields" do
    it "safely instantiates an empty stats_json hash payload cleanly on user signup" do
      # Read the record compiled automatically by the structural model hooks
      stat_record = student.user_tag_stat

      expect(stat_record).to be_valid
      expect(stat_record.stats_json).to eq({})
    end

    # =========================================================================
    # 3. SCHEMA INTEGRITY CONSTRAINT SHIELDS TESTS
    # =========================================================================
    it "blocks record creations missing a mandatory user profile index" do
      bad_stat = UserTagStat.new(user: nil)
      expect(bad_stat).not_to be_valid
    end

    # =========================================================================
    # 4. DUPLICATE LAYER INFRACTION PREVENTIONS TESTS
    # =========================================================================
    it "strictly intercepts attempts to clone duplicate tag statistic rows for the exact same user" do
      # The first cache already exists from signup, so creating another manually fails correctly
      duplicate = UserTagStat.new(user: student)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to include("A grammar tag statistics tracking cache matrix is already registered for this specific student profile")
    end
  end
end
