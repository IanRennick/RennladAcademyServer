# spec/models/user_stat_spec.rb
require "rails_helper"

RSpec.describe "Multi-Dimensional User Statistics Matrix", type: :model do
  let!(:student) { User.create!(username: "stats_tracker", email: "stats@test.com", password: "password123", role: :student) }

  describe "Data Integrity Guard Shields" do
    it "allows a valid performance metrics statistic row to save cleanly" do
      stat = UserStat.new(user: student, stat_type: "kind", stat_key: 0, times_done: 10, times_correct: 7, rating: 1250)
      expect(stat).to be_valid
    end

    it "blocks record creations containing invalid stat_type parameter strings" do
      bad_type = UserStat.new(user: student, stat_type: "invalid_axis", stat_key: 1, times_done: 1, times_correct: 1, rating: 1200)
      expect(bad_type).not_to be_valid
    end

    it "strictly rejects negative tracking integers inside counter columns" do
      broken_counters = UserStat.new(user: student, stat_type: "kind", stat_key: 0, times_done: -5, times_correct: 0, rating: 1200)
      expect(broken_counters).not_to be_valid
    end

    it "blocks anomalous entries where correct metrics exceed the total attempt counts" do
      impossible_math = UserStat.new(user: student, stat_type: "kind", stat_key: 0, times_done: 5, times_correct: 12, rating: 1200)
      expect(impossible_math).not_to be_valid
      expect(impossible_math.errors[:times_correct]).to include("cannot mathematically represent a value higher than total times_done logs")
    end

    it "strictly blocks duplicate key initializations across the exact same mapping scope" do
      UserStat.create!(user: student, stat_type: "kind", stat_key: 3, times_done: 1, times_correct: 1, rating: 1200)

      duplicate = UserStat.new(user: student, stat_type: "kind", stat_key: 3, times_done: 2, times_correct: 2, rating: 1250)
      expect(duplicate).not_to be_valid
    end
  end
end
