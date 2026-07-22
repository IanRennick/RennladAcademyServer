# spec/requests/api/v1/registrations_spec.rb
# =========================================================================
# STATELESS API V1 STUDENT ENROLLMENT GATEWAY SPEC
# - Validates high-speed account processing allocations under OAuth boundaries
# - Asserts invalid client ID keys block records from corrupting table inventories
# =========================================================================
require "rails_helper"

RSpec.describe "Stateless API V1 User Registrations Gateway Matrix", type: :request do
  # --- Setup Shared Test Matrix Variables ---
  let!(:oauth_application) { Doorkeeper::Application.create!(name: "Rennlad Client App", redirect_uri: "https://localhost/callback", scopes: "") }

  # =========================================================================
  # 1. COMPETE ONBOARDING ENROLLMENT LOG LOOPS TEST
  # =========================================================================
  describe "POST /api/v1/users" do
    context "with valid signup parameters and application identifiers" do
      it "creates the user account, returns an access token body, and drops an encrypted cookie" do
        expect {
          post "/api/v1/users", params: {
            username: "api_newcomer",
            email: "newcomer@test.com",
            password: "securepassword123",
            client_id: oauth_application.uid
          }
        }.to change(User, :count).by(1)

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json).to have_key("access_token")
        expect(json).not_to have_key("refresh_token")

        expect(cookies[:_refresh_token]).not_to be_nil
      end
    end

    # =========================================================================
    # 2. BAD APPLICATION GRANTS REJECTION SHIELD TEST
    # =========================================================================
    context "with an invalid or missing client application identifier" do
      it "rejects the processing pipeline early with an unauthorized 401 response status" do
        expect {
          post "/api/v1/users", params: {
            username: "api_orphan",
            email: "orphan@test.com",
            password: "password123",
            client_id: "corrupt_fake_client_id_123"
          }
        }.not_to change(User, :count)

        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json["error"]).to include("Client authentication failed due to unknown client")
      end
    end
  end
end
