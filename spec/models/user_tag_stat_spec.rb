require 'rails_helper'

RSpec.describe UserTagStat, type: :model do
  # Test associations
  describe "associations" do
    it { should belong_to(:user) }
  end
end
