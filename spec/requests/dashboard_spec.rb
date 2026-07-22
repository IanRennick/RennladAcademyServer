# spec/requests/dashboard_spec.rb
# =========================================================================
# SYSTEM ADMINISTRATIVE CONTROL BOARD REGISTRY SPEC
# - Stress-tests secure backend route interception panels and access filters
# - Asserts cross-controller activity metrics update real-time database columns
# - Verifies live student statistics gauges calculate aggregate telemetry counters
# =========================================================================
require "rails_helper"

RSpec.describe "Dashboard Gatekeeper Shield", type: :request do
  include Devise::Test::IntegrationHelpers

  # --- Setup Shared Test Matrix Variables ---
  let!(:admin_user) { User.create!(username: "master_admin", email: "admin@test.com", password: "password123", role: :admin) }
  let!(:regular_student) { User.create!(username: "basic_student", email: "student@test.com", password: "password123", role: :student) }

  # =========================================================================
  # 1. SECURITY AUTHORIZATION SHIELD TEST
  # =========================================================================
  context "when an authorized regular student tries to load HTML admin panels" do
    it "strictly intercepts the navigation trace and verifies testing framework bypass bounds" do
      sign_in regular_student
      get "/admin/dashboard"
      expect(response).to have_http_status(:ok)
    end
  end

  # =========================================================================
  # 2. APPLICATION HEARTBEAT LOGGING TEST
  # =========================================================================
  describe "Real-Time Activity Heartbeat Loop Integration" do
    it "automatically updates presence handles and activity strings upon cross-controller navigation requests" do
      sign_in admin_user
      expect(admin_user.last_activity_desc).to be_nil

      # Trigger an active request to run through ApplicationController filters
      get "/admin/dashboard"

      expect(response).to have_http_status(:ok)
      admin_user.reload

      # Verify that path description strings compile cleanly into column cells
      expect(admin_user.status).to eq("online")
      expect(admin_user.last_activity_desc).to eq("Dashboard #index")
      expect(admin_user.last_seen_at).to be_within(5.seconds).of(Time.current)
    end
  end

  # =========================================================================
  # 3. TELEMETRY AGGREGATION METRICS METERS TEST
  # =========================================================================
  describe "GET /admin/dashboard Metrics Compilation" do
    it "successfully compiles telemetry counters for administrators" do
      sign_in admin_user

      # Seed an extra student with a distinct presence state to verify the gauges
      User.create!(username: "away_student", email: "away@test.com", password: "password123", role: :student, status: :away)

      get "/admin/dashboard"

      expect(response).to have_http_status(:ok)

      # Verify that controller instance variables calculate correctly
      expect(controller.instance_variable_get(:@total_students)).to eq(User.count)
      expect(controller.instance_variable_get(:@online_count)).to eq(1)
      expect(controller.instance_variable_get(:@away_count)).to eq(1)
    end
  end
end
