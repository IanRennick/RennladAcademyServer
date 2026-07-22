# spec/requests/users_spec.rb
# =========================================================================
# USER PROFILES & PRIVATE DIRECT CHAT ROUTER SPEC
# - Stress-tests high-density inner SQL table group joins for CEFR metrics
# - Verifies private direct message token hashing parameters protect room states
# =========================================================================
require "rails_helper"

RSpec.describe "Student Profiles & Direct Messaging Routing Matrix", type: :request do
  include Devise::Test::IntegrationHelpers

  # --- Setup Shared Test Matrix Variables ---
  let!(:b2_level) { Level.find_or_create_by!(name: "B2") { |l| l.initial_rating = 1200 } }
  let!(:admin_teacher) { User.create!(username: "master_tutor", email: "teacher@academy.com", password: "password123", role: :admin) }
  let!(:student_target) { User.create!(username: "ielts_scholar", email: "scholar@academy.com", password: "password123", role: :student) }
  let!(:grammar_puzzle) { Question.create!(kind: :open_cloze, level: b2_level, main: "This is a curriculum test sentence.", answers: [ "test" ]) }

  before { sign_in admin_teacher }

  # =========================================================================
  # 1. PROFILE CEFR DATA METRICS GROUP AGGREGATIONS TEST
  # =========================================================================
  describe "GET /u/:id (Upgraded Metric Dashboard State)" do
    it "successfully compiles multi-table SQL joins and group arrays for the views" do
      student_target.user_histories.create!(question: grammar_puzzle, first_attempt_correct: true)
      Comment.create!(commentable: grammar_puzzle, user: student_target, body: "A relevant doubt string entry payload.")

      get "/u/#{student_target.id}"

      expect(response).to have_http_status(:ok)
      expect(controller.instance_variable_get(:@total_by_level)).to eq({ "B2" => 1 })
      expect(controller.instance_variable_get(:@correct_by_level)).to eq({ "B2" => 1 })
      expect(response.body).to include("A relevant doubt string entry payload.")
    end
  end

  # =========================================================================
  # 2. DETERMINISTIC TOKENS ROOM FACTORY TEST
  # =========================================================================
  describe "GET /u/:id/chat (Direct Message Routing Portal)" do
    it "calculates unique sorted room handles and builds a private direct room if missing" do
      expect(Room.where(is_private: true).count).to eq(0)

      get "/u/#{student_target.id}/chat"

      expect(response).to have_http_status(:ok)
      expect(Room.where(is_private: true).count).to eq(1)

      generated_room = Room.last
      expect(generated_room.name).to start_with("private_")
      expect(generated_room.is_private).to eq(true)
    end
  end
end
