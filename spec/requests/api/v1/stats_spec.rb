# spec/requests/api/v1/stats_spec.rb
# =========================================================================
# STATELESS API V1 PERFORMANCE STATS DATALINE SPEC
# - Validates floating daily delta rating variance math blocks are accurate
# - Asserts chronological order sequence sorting applies to progress timelines
# =========================================================================
require "rails_helper"

RSpec.describe "Api::V1::Stats Endpoints", type: :request do
  # --- Setup Shared Test Matrix Variables ---
  let!(:user) { User.create!(username: "stats_student", email: "stats@example.com", password: "password123", rating: 1350) }

  # =========================================================================
  # 1. VISITOR SECURITY WALL VALIDATIONS TEST
  # =========================================================================
  describe "GET /api/v1/stats" do
    context "when a logged-out guest or missing token attempts to query analytics parameters" do
      it "strictly rejects the tracking query and returns a 401 unauthorized status code" do
        allow_any_instance_of(Api::V1::StatsController).to receive(:current_user).and_return(nil)

        get "/api/v1/stats"

        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json["error"]).to eq("Valid OAuth Bearer token authentication required.")
      end
    end

    # =========================================================================
    # 2. DELTA ARITHMETIC & ENUM RE-MAPPING LOOPS TEST
    # =========================================================================
    context "when an authenticated student pulls their performance card" do
      before do
        user.user_stats.create!(stat_type: "kind", stat_key: 0, times_done: 5, times_correct: 4, rating: 1280)

        user.elo_snapshots.create!(rating: 1200, recorded_on: 2.days.ago)
        user.elo_snapshots.create!(rating: 1250, recorded_on: 1.day.ago)
        user.elo_snapshots.create!(rating: 1350, recorded_on: Date.current)

        allow_any_instance_of(Api::V1::StatsController).to receive(:current_user).and_return(user)
      end

      it "returns a successful 200 response with pre-populated maps and ascending chronological charts history" do
        get "/api/v1/stats"

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json["global_rating"]).to eq(1350)
        expect(json["daily_delta"]).to eq(100) # 1350 - 1250

        expect(json["elo_history"].size).to eq(3)
        expect(json["elo_history"].first["rating"]).to eq(1200)
        expect(json["elo_history"].last["rating"]).to eq(1350)

        expect(json["puzzle_types"]).to have_key("multiple_choice")
        expect(json["puzzle_types"]["multiple_choice"]["done"]).to eq(5)
        expect(json["puzzle_types"]["open_cloze"]["done"]).to eq(0)
      end
    end
  end
end
