# spec/requests/api/v1/notifications_spec.rb
# =========================================================================
# STATELESS API V1 NOTIFICATIONS CONTROL WORKFLOW SPEC
# - Stress-tests token-isolated alert collection arrays for React navbars
# - Verifies single toggle hooks and bulk database clearing macro updates
# =========================================================================
require "rails_helper"

RSpec.describe "Stateless API V1 Notifications Control Matrix", type: :request do
  include Devise::Test::IntegrationHelpers

  # --- Setup Shared Test Matrix Variables ---
  let!(:admin_teacher) { User.create!(username: "api_moderator", email: "teacher@academy.com", password: "password123", role: :admin) }
  let!(:student_user) { User.create!(username: "api_scholar", email: "student@academy.com", password: "password123", role: :student) }

  # Seed a real-time notification alert record node
  let!(:alert_item) do
    Notification.create!(
      recipient: student_user,
      actor: admin_teacher,
      event_type: "system_alert",
      params: { "message" => "corrected your essay assignment", "url" => "/writings/1" }
    )
  end

  before do
    # Bind our authentication helper mock directly to the targeted API controller thread instance
    allow_any_instance_of(Api::V1::NotificationsController).to receive(:current_user).and_return(student_user)
  end

  # =========================================================================
  # 1. API NOTIFICATIONS FETCH ENGINE TEST
  # =========================================================================
  describe "GET /api/v1/notifications" do
    it "returns data arrays containing count gauges and string parameters cleanly" do
      get "/api/v1/notifications"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json).to have_key("unread_count")
      expect(json["notifications"].first["id"]).to eq(alert_item.id)
      expect(json["notifications"].first["message"]).to eq("corrected your essay assignment")
    end
  end

  # =========================================================================
  # 2. SINGLE STATE TOGGLE PORTALS TEST
  # =========================================================================
  describe "PATCH /api/v1/notifications/:id" do
    it "successfully updates timestamps and toggles read metrics boolean values" do
      patch "/api/v1/notifications/#{alert_item.id}"

      expect(response).to have_http_status(:ok)
      alert_item.reload
      expect(alert_item.read_at).not_to be_nil
    end
  end

  # =========================================================================
  # 3. BULK DATABASE CLEARING MACROS TEST
  # =========================================================================
  describe "POST /api/v1/notifications/mark_all_as_read" do
    it "performs an instant collection sweep resetting unread counts down to zero" do
      post "/api/v1/notifications/mark_all_as_read"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["unread_count"]).to eq(0)
      expect(student_user.notifications.unread.count).to eq(0)
    end
  end
end
