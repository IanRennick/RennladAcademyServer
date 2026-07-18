# spec/requests/api/v1/stats_spec.rb
require "rails_helper"

RSpec.describe "Api::V1::Stats Endpoints", type: :request do
  let!(:user) { User.create!(username: "stats_student", email: "stats@example.com", password: "password123", rating: 1350) }

  describe "GET /api/v1/stats" do
    context "when a logged-out guest attempts to query analytics parameters" do
      it "strictly rejects the tracking query and returns a 401 unauthorized status code" do
        # Emulate a request where token verification fails and evaluates to nil
        allow_any_instance_of(ApiController).to receive(:current_user).and_return(nil)

        get "/api/v1/stats"

        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json["error"]).to eq("Unauthorized")
      end
    end

    context "when an authenticated student pulls their performance card" do
      before do
        # Seed user category metric stats rows
        user.user_stats.create!(stat_type: "kind", stat_key: 0, times_done: 5, times_correct: 4, rating: 1280) # multiple_choice

        # Seed historical Elo tracking timeline milestones
        user.elo_snapshots.create!(rating: 1200, recorded_on: 2.days.ago)
        user.elo_snapshots.create!(rating: 1250, recorded_on: 1.day.ago)
        user.elo_snapshots.create!(rating: 1350, recorded_on: Date.current)

        # Force authentication check hooks to bind cleanly to our active student record
        allow_any_instance_of(ApiController).to receive(:current_user).and_return(user)
      end

      it "returns a successful 200 response with pre-populated maps and ascending chronological charts history" do
        get "/api/v1/stats"

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        # Core global checks
        expect(json["global_rating"]).to eq(1350)

        # ✅ VERIFY DYNAMIC HISTORICAL CHRONOLOGICAL SEQUENCE SORTING
        expect(json["elo_history"].size).to eq(3)
        expect(json["elo_history"].first["rating"]).to eq(1200)
        expect(json["elo_history"].last["rating"]).to eq(1350)

        # Verify pre-populated enum mapping structures exist securely
        expect(json["puzzle_types"]).to have_key("multiple_choice")
        expect(json["puzzle_types"]["multiple_choice"]["done"]).to eq(5)
        expect(json["puzzle_types"]["multiple_choice"]["correct"]).to eq(4)
        expect(json["puzzle_types"]["multiple_choice"]["rating"]).to eq(1280)

        # Verify unplayed category default blocks populate safely as zeros
        expect(json["puzzle_types"]).to have_key("open_cloze")
        expect(json["puzzle_types"]["open_cloze"]["done"]).to eq(0)
        expect(json["puzzle_types"]["open_cloze"]["rating"]).to eq(1200)
      end
    end
  end
end
