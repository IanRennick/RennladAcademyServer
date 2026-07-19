# spec/models/tag_spec.rb
require "rails_helper"

RSpec.describe "Grammatical Tag Directory Engine", type: :model do
  describe "Data Integrity Guard Shields" do
    it "automatically cleanses whitespaces, downcases characters, and strips raw hashtags before validation" do
      tag = Tag.create!(name: "  #Conditionals!  ")
      expect(tag.name).to eq("conditionals")
    end

    it "blocks the creation of tags that reduce to a completely empty name string" do
      bad_tag = Tag.new(name: "!!!")
      expect(bad_tag).not_to be_valid
      expect(bad_tag.errors[:name]).to include("can't be blank")
    end

    it "enforces strict unique case-insensitive constraints across all database columns" do
      Tag.create!(name: "inversions")
      duplicate = Tag.new(name: "Inversions")
      expect(duplicate).not_to be_valid
    end
  end
end
