require 'rails_helper'

RSpec.describe EloCalculator do
  describe ".calculate" do
    let(:user_elo) { 1200 }
    let(:question_elo) { 1200 }

    context "when a record is PROVISIONAL (fewer than 20 completions)" do
      it "applies a highly volatile point swing multiplier (K=64)" do
        # Scenario: Brand new user (0 completions) beats a balanced question
        new_user_rating, _new_q_rating = EloCalculator.calculate(user_elo, question_elo, true, 0, 25)

        # User point calculation: 1200 + (64 * (1.0 - 0.5)) = 1232
        expect(new_user_rating).to eq(1232)
      end
    end

    context "when a record is STABILIZED (20 or more completions)" do
      it "applies a steady point swing multiplier (K=32)" do
        # Scenario: Seasoned user (50 completions) beats a balanced question
        stable_user_rating, _new_q_rating = EloCalculator.calculate(user_elo, question_elo, true, 50, 25)

        # User point calculation: 1200 + (32 * (1.0 - 0.5)) = 1216
        expect(stable_user_rating).to eq(1216)
      end
    end

    context "when computing puzzle performance probabilities" do
      it "adjusts ratings strictly based on difficulty matching expectations" do
        # Scenario: A weak user (1000 Elo) blunders against a hard question (1400 Elo)
        # The system expects the user to fail, so rating changes should be very small
        new_user_rating, new_question_rating = EloCalculator.calculate(1000, 1400, false, 50, 50)

        expect(new_user_rating).to be_within(5).of(1000) # Negligible loss for the user
        expect(new_question_rating).to be_within(5).of(1400) # Negligible gain for the question
      end
    end
  end
end
