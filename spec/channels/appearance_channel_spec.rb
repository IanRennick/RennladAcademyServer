# spec/channels/appearance_channel_spec.rb
# =========================================================================
# WEBSOCKET APPEARANCE PRESENCE CONNECTIONS SPEC
# - Stress-tests subscription confirmations linking listeners safely
# - Asserts client event triggers mutate relational state fields to away
# =========================================================================
require "rails_helper"

RSpec.describe AppearanceChannel, type: :channel do
  # --- Setup Shared Test Matrix Variables ---
  let!(:student) { User.create!(username: "presence_tester", email: "tracker@test.com", password: "password123", role: :student) }

  before { stub_connection current_user: student }

  # =========================================================================
  # 1. SUBSCRIPTION LIFECYCLE HOOKS TEST
  # =========================================================================
  describe "Subscription Connection Lifecycle Loops" do
    it "successfully registers the stream subscription and marks the user online automatically" do
      subscribe

      expect(subscription).to be_confirmed
      expect(subscription).to have_stream_from("appearance_channel")

      student.reload
      expect(student.status).to eq("online")
    end

    it "handles client unsubscription loops and purges active presence rows" do
      subscribe
      unsubscribe

      student.reload
      expect(student.status).to eq("offline")
    end
  end

  # =========================================================================
  # 2. STATE CLIENT TRANSITION PARSING TEST
  # =========================================================================
  describe "State Inter-Process Actions" do
    it "successfully parses raw client actions to transition statuses into away states" do
      subscribe
      perform :away

      student.reload
      expect(student.status).to eq("away")
    end
  end
end
