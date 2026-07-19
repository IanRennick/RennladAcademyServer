# spec/models/elo_snapshot_spec.rb
require "rails_helper"

RSpec.describe "Historical Elo Snapshot Engine", type: :model do
  let!(:student) { User.create!(username: "history_buff", email: "history@test.com", password: "password123", role: :student) }

  describe "Data Integrity Guard Shields" do
    it "safely instantiates an empty category hash payload if none is explicitly passed on creation" do
      snapshot = EloSnapshot.create!(user: student, rating: 1250, recorded_on: Date.current)

      expect(snapshot).to be_valid
      expect(snapshot.category_ratings).to eq({})
    end

    it "blocks snapshot records from saving if they are missing required calendar dates or ratings" do
      bad_snapshot = EloSnapshot.new(user: student, rating: nil, recorded_on: nil)
      expect(bad_snapshot).not_to be_valid
    end

    it "strictly rejects negative numbers or corrupt rating strings" do
      broken_rating = EloSnapshot.new(user: student, rating: -100, recorded_on: Date.current)
      expect(broken_rating).not_to be_valid
    end
  end
end
