# spec/requests/chatroom_interface_spec.rb
# =========================================================================
# WEBSOCKET CHATROOM INTERFACE SYSTEM SPEC
# - Stress-tests UI frame generation layouts for core communication rooms
# - Asserts sidebar panels populate active public user indices and room streams
# - Verifies structural message card wrappers decouple message state threads
# =========================================================================
require "rails_helper"

RSpec.describe "WebSocket Chatroom Interface System", type: :request do
  include Devise::Test::IntegrationHelpers

  # --- Setup Shared Test Matrix Variables ---
  let!(:student_user) { User.create!(username: "chatty_student", email: "chatty@test.com", password: "password123", role: :student) }
  let!(:peer_user) { User.create!(username: "study_buddy", email: "buddy@test.com", password: "password123", role: :student) }
  let!(:public_room) { Room.create!(name: "ielts-grammar-hub") }

  # Seed a test conversation message stream row inside our target room
  let!(:chat_message) { Message.create!(user: peer_user, room: public_room, body: "Hey everyone! Welcome to the new study channel layout.") }

  # =========================================================================
  # 1. APPLICATION SIDEBAR CHAT SUITE NAVIGATION FRAMEWORK TEST
  # =========================================================================
  describe "GET /rooms (Master Communication Suite Framework)" do
    context "when an authenticated student opens the chat hub" do
      before { sign_in student_user }

      it "renders the premium dark workspace layout frame and displays active student lists" do
        get "/rooms"

        expect(response).to have_http_status(:ok)

        # 1. Verify that the master overflow-hidden container grid compiles
        expect(response.body).to include('id="chatroom_container"')
        expect(response.body).to include('id="side_panel"')

        # 2. Verify that active student and room navigation list sections display cleanly
        expect(response.body).to include("Active Students")
        expect(response.body).to include("Discussion Channels")
        expect(response.body).to include(peer_user.username)
        expect(response.body).to include(public_room.name)

        # 3. Verify that the high-visibility unselected placeholder display card loads natively
        expect(response.body).to include("Academy Communication Suite")
        expect(response.body).to include("Select an active study channel")
      end
    end
  end

  # =========================================================================
  # 2. CHAT STREAM VIEW ELEMENT SELECTION MOUNTS TEST
  # =========================================================================
  describe "GET /rooms/:id (Active Chat Thread Window State)" do
    context "when a student selects a specific study channel path link" do
      before { sign_in student_user }

      it "renders the message scroll containers, inputs, and decouples bubbles from warden thread variables" do
        # Trigger controller assignment loops by loading the single room state parameters
        get "/rooms/#{public_room.id}"

        expect(response).to have_http_status(:ok)

        # 1. Verify that the chat thread header name compiles without extra characters
        expect(response.body).to include(public_room.name)
        expect(response.body).to include("Room ID: #{public_room.id}")

        # 2. Verify that the message body strings display inside the card blocks
        expect(response.body).to include("chat-message-wrapper")
        expect(response.body).to include("data-sender-id=\"#{peer_user.id}\"")
        expect(response.body).to include(chat_message.body)

        # 3. Verify that the message entry input box and room creators render safely
        expect(response.body).to include('class="form-control bg-black border-secondary text-white font-sans py-2 msg-content"')
        expect(response.body).to include('placeholder="Create channel name..."')
      end
    end
  end
end
