require 'rails_helper'

RSpec.describe "Api::V1::Registrations", type: :request do
  # Create a Doorkeeper Application to generate a valid client_id
  let!(:application) { Doorkeeper::Application.create!(name: "Frontend Client", redirect_uri: "urn:ietf:wg:oauth:2.0:oob", uid: "imv3SELnwic1eZYgohTlnf_ixo7xUVT_6t0_PyR5sRc", secret: "456") }

  describe "POST /api/v1/users" do
    let(:valid_attributes) do
      {
        email: "new_student@example.com",
        name: "Jeff",
        password: "password123",
        password_confirmation: "password123",
        client_id: application.uid # Passes the mock frontend client_id
      }
    end

    # Test with valid credentials
    context "with valid parameters" do
      it "creates a new User and returns a successful status" do
        expect {
          post "/api/v1/users",
               params: valid_attributes.to_json,
               headers: { "CONTENT_TYPE" => "application/json", "ACCEPT" => "application/json" }
        }.to change(User, :count).by(1)

        expect(response).to have_http_status(:created).or(have_http_status(:ok))
      end
    end

    # Test with invalid credentials
    context "with invalid parameters (missing password)" do
      it "does not create a user and returns validation errors" do
        invalid_attributes = {
          email: "bad_email@example.com",
          name: "Jeff",
          password: "",
          client_id: application.uid
        }

        expect {
          post "/api/v1/users",
               params: invalid_attributes.to_json,
               headers: { "CONTENT_TYPE" => "application/json", "ACCEPT" => "application/json" }
        }.not_to change(User, :count)

        expect(response).to have_http_status(:unprocessable_entity).or(have_http_status(:ok))
      end
    end
  end
end
