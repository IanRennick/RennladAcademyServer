# spec/models/level_spec.rb
require "rails_helper"

RSpec.describe "CEFR Level Hierarchy Engine", type: :model do
  describe "Data Integrity Guard Shields" do
    it "automatically cleanses trailing whitespace strings and forces uppercase conversions on save" do
      lvl = Level.create!(name: "  c1  ")
      expect(lvl.name).to eq("C1")
    end

    it "blocks the creation of levels containing non-CEFR standard character formats" do
      bad_lvl = Level.new(name: "Z9")
      expect(bad_lvl).not_to be_valid
      expect(bad_lvl.errors[:name]).to include("must represent a valid system-supported CEFR code format profile string (e.g. B2, C1)")
    end

    it "enforces full unique case-insensitive constraints across all database columns" do
      Level.create!(name: "B2")
      duplicate = Level.new(name: "b2")
      expect(duplicate).not_to be_valid
    end
  end
end
