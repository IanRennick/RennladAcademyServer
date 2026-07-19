# spec/services/elo_calculator_spec.rb
require "rails_helper"

RSpec.describe EloCalculator, type: :service do
  describe ".calculate" do
    context "when a student earns a perfect win (1.0)" do
      it "gains points while the question decays proportionally" do
        new_user, new_q = EloCalculator.calculate(1200, 1200, 1.0, 50, 50)

        expect(new_user).to be > 1200
        expect(new_q).to be < 1200
      end
    end

    context "when an account is provisional (under 20 puzzles solved)" do
      it "triggers a higher K-factor weighting to shift ratings faster" do
        provisional_user, _ = EloCalculator.calculate(1200, 1200, 1.0, 5, 50)
        stable_user, _      = EloCalculator.calculate(1200, 1200, 1.0, 50, 50)

        # High provisional weighting forces a larger point shift on win cycles
        expect(provisional_user).to be > stable_user
      end
    end

    context "when a student earns V2 fractional partial credit (0.5)" do
      it "calculates precise floating-point variance values seamlessly" do
        new_user, _ = EloCalculator.calculate(1200, 1200, 0.5, 50, 50)

        # At an exact equal rating match, expecting a 0.5 outcome results in a 0 delta adjustment shift
        expect(new_user).to eq(1200)
      end
    end

    context "when ratings collapse heavily towards zero" do
      it "enforces an absolute system boundary floor line of 100 Elo" do
        low_user, low_q = EloCalculator.calculate(100, 2000, 0.0, 50, 50)

        expect(low_user).to eq(100)
        expect(low_q).to be >= 100
      end
    end
  end
end
