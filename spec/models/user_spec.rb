require 'rails_helper'

RSpec.describe User, type: :model do
  # Test associations
  describe "puzzle stats associations" do
    it { should have_many(:user_stats).dependent(:destroy) }
    it { should have_one(:user_tag_stat).dependent(:destroy) }
    it { should have_many(:user_histories).dependent(:destroy) }
  end

  # 2. Test Stats logic
  describe "puzzle stats logic" do
    # Test that an empty scoreboard is created for a new user
    it "automatically creates an empty user_tag_stat record after creation" do
      user = User.create!(
        username: "test_student",
        email: "student@example.com",
        password: "securepassword123",
        password_confirmation: "securepassword123"
      )

      expect(user.user_tag_stat).to_not be_nil
      expect(user.user_tag_stat.stats_json).to eq({})
    end

    # Test the complex tag calculations
    it "successfully initializes and updates nested tag metrics inside the JSON payload" do
      # Create test User
      user = User.create!(
        username: "test_student_two",
        email: "student2@example.com",
        password: "securepassword123",
        password_confirmation: "securepassword123"
      )

      # Scenario A: Correct response creates the tags with provisional Elo boost
      user.update_tag_metrics([ "phrasal" ], 1200, true)

      user.reload
      expect(user.user_tag_stat.stats_json["phrasal"]).to eq({ "done" => 1, "correct" => 1, "rating" => 1232 })

      # Scenario B: Incorrect response increments done tally and calculates Elo drop
      user.update_tag_metrics([ "phrasal" ], 1200, false)

      user.reload
      expect(user.user_tag_stat.stats_json["phrasal"]).to eq({ "done" => 2, "correct" => 1, "rating" => 1197 })
    end
  end
end
