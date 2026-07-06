require 'rails_helper'

RSpec.describe "CustomTokens", type: :request do
  # Setup an active, verified application and user record in Doorkeeper's schema registry
  let!(:application) { Doorkeeper::Application.create!(name: "Frontend Client", redirect_uri: "urn:ietf:wg:oauth:2.0:oob", uid: "123", secret: "456") }
  let!(:user) { User.create!(email: "auth_tester@example.com", password: "password123", password_confirmation: "password123") }

  # Test with valid credentials
  describe "POST /api/v1/oauth/token" do
    context "when authenticating with a valid password grant" do
      it "returns the access token in the JSON body and hides the refresh token inside a secure cookie" do
        # Post standard password grant parameters to your token path
        post "/api/v1/oauth/token", params: {
          grant_type: "password",
          client_id: application.uid,
          client_secret: application.secret,
          email: user.email,
          password: "password123"
        }

        # Verify authentication success
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        # Check JSON Body: Must give the frontend its short-lived access authorization
        expect(json).to have_key("access_token")
        expect(json).to_not have_key("refresh_token") # Ensure it is strictly hidden from javascript body reads!

        # Check Cookies: Verifycustom controller injected the refresh token into the browser stack
        expect(response.cookies).to have_key("_refresh_token")

        # Verify the cookie flags protect against cross-site scripting vulnerabilities
        cookie_header = response.headers["Set-Cookie"]
        expect(cookie_header).to include("httponly")
        expect(cookie_header).to include("samesite=lax").or(include("samesite=strict"))
      end
    end

    # Test with invalid credentials
    context "with invalid credentials" do
      it "returns a 400 Bad Request error status" do
        post "/api/v1/oauth/token", params: {
          grant_type: "password",
          client_id: application.uid,
          client_secret: application.secret,
          email: user.email,
          password: "wrong_password"
        }

        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json["error"]).to eq("invalid_grant")
      end
    end
  end
end
