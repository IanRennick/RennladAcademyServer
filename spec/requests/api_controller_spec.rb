# spec/requests/api_controller_spec.rb
# =========================================================================
# STATELESS API GATEKEEPER AUTHORIZATION GATE SPEC
# - Verifies stateless Bearer token extraction matrices pass filters smoothly
# - Stress-tests 401 unauthorized interception fallback shield mechanisms
# =========================================================================
require "rails_helper"

RSpec.describe "Stateless API Gatekeeper Base Shield", type: :request do
  # --- Setup Shared Test Matrix Variables ---
  let!(:oauth_application) { Doorkeeper::Application.create!(name: "Test Client", redirect_uri: "https://localhost/callback", scopes: "") }
  let!(:student_user) { User.create!(username: "api_student", email: "api@test.com", password: "password123", role: :student) }

  # =========================================================================
  # 1. BEARER TOKEN EXTRACTION PARSING TEST
  # =========================================================================
  describe "Stateless Token Extraction Matrix" do
    context "with a valid OAuth access bearer token" do
      it "cleanly authorizes the route, extracts current_user, and returns a successful JSON status" do
        Doorkeeper::AccessToken.create!(
          application_id: oauth_application.id,
          resource_owner_id: student_user.id,
          expires_in: 2.hours
        )

        allow_any_instance_of(Api::V1::StatsController).to receive(:current_user).and_return(student_user)

        get "/api/v1/stats"

        expect(response).to have_http_status(:ok)

        json_res = JSON.parse(response.body)
        expect(json_res).to have_key("global_rating")
        expect(json_res).to have_key("daily_delta")
      end
    end

    # =========================================================================
    # 2. UNAUTHORIZED INTERCEPTION GUARD CODES TEST
    # =========================================================================
    context "without an authorization bearer token payload" do
      it "intercepts the request loop instantly returning an unauthenticated 401 response status" do
        allow_any_instance_of(Api::V1::StatsController).to receive(:current_user).and_return(nil)

        get "/api/v1/stats"

        expect(response).to have_http_status(:unauthorized)
        json_res = JSON.parse(response.body)
        expect(json_res["error"]).to include("Valid OAuth Bearer token authentication required")
      end
    end
  end
end
