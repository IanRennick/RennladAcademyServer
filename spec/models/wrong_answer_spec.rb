require 'rails_helper'

RSpec.describe WrongAnswer, type: :model do
  # Test associations
  describe "associations" do
    it { should belong_to(:question) }
  end

  # Test validations
  describe "validations" do
    it { should validate_presence_of(:answer_text) }
  end
end
