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
        email: "student2@example.com",
        password: "securepassword123",
        password_confirmation: "securepassword123"
      )

      # Scenario A: User answers a question with 'phrasal' and 'future' tags CORRECTLY
      user.update_tag_metrics([ "phrasal", "future" ], true)

      # Refresh the record to read the database update
      user.reload
      expect(user.user_tag_stat.stats_json["phrasal"]).to eq({ "done" => 1, "correct" => 1 })
      expect(user.user_tag_stat.stats_json["future"]).to eq({ "done" => 1, "correct" => 1 })

      # Scenario B: User answers another question with the 'phrasal' tag INCORRECTLY
      user.update_tag_metrics([ "phrasal" ], false)

      user.reload
      # Phrasal 'done' should increment to 2, but 'correct' stays at 1
      expect(user.user_tag_stat.stats_json["phrasal"]).to eq({ "done" => 2, "correct" => 1 })
      # Future should remain unchanged
      expect(user.user_tag_stat.stats_json["future"]).to eq({ "done" => 1, "correct" => 1 })
    end
  end
end
