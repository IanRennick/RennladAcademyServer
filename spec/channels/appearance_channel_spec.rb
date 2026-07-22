# spec/channels/appearance_channel_spec.rb
require "rails_helper"

RSpec.describe AppearanceChannel, type: :channel do
  # --- Setup Shared Test Matrix Variables ---
  let!(:student) { User.create!(username: "presence_tester", email: "tracker@test.com", password: "password123", role: :student) }

  before do
    # Bind our test user instance to the ApplicationCable connection mocking thread context
    stub_connection current_user: student
  end

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
      expect(student.status).to eq("online")

      # Simulates the client socket connection tearing down or closing
      unsubscribe

      student.reload
      expect(student.status).to eq("offline")
    end
  end

  describe "State Inter-Process Actions" do
    it "successfully parses raw client actions to transition statuses into away states" do
      subscribe

      # Simulates the client browser transmitting an 'away' payload packet down the wire
      perform :away

      student.reload
      expect(student.status).to eq("away")
    end
  end
end
