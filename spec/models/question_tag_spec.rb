require 'rails_helper'

RSpec.describe QuestionTag, type: :model do
  # Test associations
  describe "associations" do
    it { should belong_to(:question) }
    it { should belong_to(:tag) }
  end
end
