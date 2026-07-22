# spec/requests/messages_spec.rb
# =========================================================================
# CHAT MESSAGES REAL-TIME INGESTION SPEC
# - Stress-tests Rails 8 strict parameter filtering boundaries on chat text
# - Verifies validation barriers prevent corrupt empty strings from saving
# =========================================================================
require "rails_helper"

RSpec.describe "Communications Messages Ingestion Endpoints", type: :request do
  include Devise::Test::IntegrationHelpers

  # --- Setup Shared Test Matrix Variables ---
  let!(:admin_user) { User.create!(username: "chat_admin", email: "admin@test.com", password: "password123", role: :admin) }
  let!(:public_room) { Room.create!(name: "general-curriculum-lounge", is_private: false) }

  before { sign_in admin_user }

  # =========================================================================
  # 1. PARAMETERS SHIELD INGESTION VALIDATIONS TEST
  # =========================================================================
  describe "POST /rooms/:room_id/messages" do
    context "with valid parameters" do
      it "successfully stores the chat entry and returns an authorized status loop code" do
        expect {
          post "/rooms/#{public_room.id}/messages", params: { message: { body: "Testing the real-time controller ingestion packet." } }
        }.to change(Message, :count).by(1)

        expect(response).to have_http_status(:no_content).or(have_http_status(:ok))
      end
    end

    context "with invalid parameters" do
      it "intercepts blank submissions and prevents database record generation" do
        expect {
          post "/rooms/#{public_room.id}/messages", params: { message: { body: "" } }
        }.not_to change(Message, :count)
      end
    end
  end
end
