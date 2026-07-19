# spec/models/user_tag_stat_spec.rb
require "rails_helper"

RSpec.describe UserTagStat, type: :model do
  let!(:student) { User.create!(username: "analytics_genius", email: "stats@test.com", password: "password123", role: :student) }

  describe "Associations Matrix" do
    it { should belong_to(:user) }
  end

  describe "Data Integrity Guard Shields" do
    it "safely instantiates an empty stats_json hash payload cleanly on user signup" do
      # FIXED: Read the record built automatically by the after_create hook!
      stat_record = student.user_tag_stat

      expect(stat_record).to be_valid
      expect(stat_record.stats_json).to eq({})
    end

    it "blocks record creations missing a mandatory user profile index" do
      bad_stat = UserTagStat.new(user: nil)
      expect(bad_stat).not_to be_valid
    end

    it "strictly intercepts attempts to clone duplicate tag statistic rows for the exact same user" do
      # FIXED: The first one already exists from signup, so creating another manually fails correctly!
      duplicate = UserTagStat.new(user: student)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to include("A grammar tag statistics tracking cache matrix is already registered for this specific student profile")
    end
  end
end
