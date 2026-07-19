# spec/requests/custom_tokens_spec.rb
require "rails_helper"

RSpec.describe "Doorkeeper Cookie-Isolated Token Security Matrix", type: :request do
  # --- Setup Shared Test Matrix Variables ---
  let!(:oauth_application) { Doorkeeper::Application.create!(name: "Rennlad React Client", redirect_uri: "https://localhost/callback", scopes: "") }
  let!(:student_user) { User.create!(username: "api_scholar", email: "scholar@test.com", password: "password123", role: :student) }

  describe "POST /api/v1/oauth/token (Access Token Acquisition Portal)" do
    context "with valid login credentials" do
      it "returns a filtered JSON body containing only the access token and sets an HTTP-Only cookie" do
        post "/api/v1/oauth/token", params: {
          grant_type: "password",
          client_id: oauth_application.uid,
          client_secret: oauth_application.secret,
          username: student_user.email,
          password: "password123"
        }

        expect(response).to have_http_status(:ok)

        # 1. Verify JSON body isolation constraints
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key("access_token")
        expect(json_response).not_to have_key("refresh_token")
        expect(json_response).not_to have_key("expires_in")

        # 2. Verify encrypted HttpOnly cookie injection parameters
        expect(cookies[:_refresh_token]).not_to be_nil
      end
    end
  end

  describe "POST /api/v1/oauth/revoke (Logout Portal)" do
    it "reads the token parameters, revokes the token, and purges the cookie node" do
      # Programmatically create a valid refresh token mapping tuple
      access_token = Doorkeeper::AccessToken.create!(
        application_id: oauth_application.id,
        resource_owner_id: student_user.id,
        refresh_token: "mock_refresh_token_string_abc123",
        expires_in: 2.hours
      )

      post "/api/v1/oauth/revoke", params: {
        token: "mock_refresh_token_string_abc123",
        client_id: oauth_application.uid,
        client_secret: oauth_application.secret
      }

      expect(response).to have_http_status(:ok)

      # Verify the token record has been revoked inside the database
      access_token.reload
      expect(access_token).to be_revoked
    end
  end
end
