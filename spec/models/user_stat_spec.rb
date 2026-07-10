require 'rails_helper'

RSpec.describe UserStat, type: :model do
  # Test associations
  describe "associations" do
    it { should belong_to(:user) }
  end

  # Test validations
  describe "validations" do
    it { should validate_inclusion_of(:stat_type).in_array(%w[kind subtype]) }
    it { should validate_presence_of(:stat_key) }

    # Test uniqueness of the combination
    context "uniqueness index" do
      # Create a test user
      let(:user) { User.create!(username: "stat_tester", email: "test@example.com", password: "password123") }

      # Link our test subject to the newly created user
      subject { UserStat.new(user_id: user.id, stat_type: "kind", stat_key: 0) }

      it { should validate_uniqueness_of(:stat_key).scoped_to(:user_id, :stat_type) }
    end
  end

  # Test before_validation default counter trigger
  describe "callbacks" do
    context "before validation on create" do
      it "automatically sets times_done and times_correct to 0 if left blank" do
        # Initialize a brand new stat record without the counter numbers
        stat = UserStat.new(
          user_id: 1,
          stat_type: "kind",
          stat_key: 0
        )

        # Trigger the validation loop
        stat.valid?

        # Verify custom model method stepped in and changed nil to 0
        expect(stat.times_done).to eq(0)
        expect(stat.times_correct).to eq(0)
      end

      it "does not overwrite values if they are purposefully provided" do
        # Initialize a stat record where the numbers are already specified
        stat = UserStat.new(
          user_id: 1,
          stat_type: "kind",
          stat_key: 0,
          times_done: 5,
          times_correct: 3
        )

        # Trigger validation loop
        stat.valid?

        # Verify it didn't reset them back to 0
        expect(stat.times_done).to eq(5)
        expect(stat.times_correct).to eq(3)
      end
    end
  end
end
