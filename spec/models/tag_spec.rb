require 'rails_helper'

RSpec.describe Tag, type: :model do
  # Test associations
  describe "associations" do
    it { should have_many(:question_tags).dependent(:destroy) }
    it { should have_many(:questions).through(:question_tags) }
  end

  # Test validations
  describe "validations" do
    it { should validate_presence_of(:name) }

    # Test uniqueness of name
    context "uniqueness" do
      subject { Tag.new(name: "first_conditional") }
      it { should validate_uniqueness_of(:name).case_insensitive }
    end
  end
end
