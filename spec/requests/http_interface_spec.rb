require 'rails_helper'

RSpec.describe "HTTP Admin Interface System", type: :request do
  include Devise::Test::IntegrationHelpers
  include Pagy::Frontend

  # Ensure base database records are instantiated in the correct structural order
  let!(:b2_level) { Level.find_or_create_by!(name: "B2") { |l| l.initial_rating = 1200 } }
  let!(:admin_user) { User.create!(username: "head_teacher", email: "admin@academy.com", password: "password123", password_confirmation: "password123", role: :admin) }

  before do
    # Sign in the admin user securely before the request block triggers execute
    sign_in admin_user

    # Seed exactly 26 sequential questions to explicitly trigger Pagy pagination boundaries
    26.times do |i|
      Question.create!(
        kind: :open_cloze,
        level: b2_level,
        main: "This is test question number #{i}.",
        answers: [ "test" ]
      )
    end
  end

  # =========================================================================
  # 1. MASTER PUZZLE LIBRARY GRID INTERFACE TEST
  # =========================================================================
  describe "GET /questions (The Curriculum Library)" do
    it "renders the analytics dashboard, filters, and paginates rows to exactly 25 items" do
      get "/questions"

      expect(response).to have_http_status(:ok)

      # ✅ SYNCED: Matches our polished typography label headers exactly
      expect(response.body).to include("Database Topology & Stock Balance Control Board")
      expect(response.body).to include("Filter Engine")

      # Pagy Verification: Verifies item 25 loads on Page 1 while item 0 is pushed to Page 2
      expect(response.body).to include("This is test question number 25.")
      expect(response.body).to_not include("This is test question number 0.")
      expect(response.body).to include("class=\"page-item\"")
    end
  end

  # =========================================================================
  # 2. STUDENT SCORES & PROFILE METRICS DASHBOARD TEST
  # =========================================================================
  describe "GET /users/:id (The Student Profile Dashboard)" do
    it "renders the multi-dimensional Elo metrics, CEFR accuracy tracker, and comments feed" do
      question_item = Question.first
      admin_user.user_histories.create!(question: question_item, first_attempt_correct: true, needs_review: false)
      Comment.create!(commentable: question_item, user: admin_user, body: "I am confused about this specific tag mapping parameter.")

      get user_path(admin_user)

      expect(response).to have_http_status(:ok)

      # ✅ SYNCED: Updated check strings to match your new high-contrast layout labels perfectly
      expect(response.body).to include("CEFR Tier Accuracy Map")
      expect(response.body).to include("Target Review Areas (<50% Acc)")
      expect(response.body).to include("Recent Student Doubts & Comments")
      expect(response.body).to include("I am confused about this specific tag mapping parameter.")
    end
  end

  # =========================================================================
  # 3. INDIVIDUAL PUZZLE DOSSIER BOARD PANEL TEST
  # =========================================================================
  describe "GET /questions/:id (The Puzzle Dossier Board)" do
    let!(:dossier_question) do
      Question.create!(
        kind: :sentence_cloze,
        subtype: :sc_conditional,
        level: b2_level,
        main: "If I * a million euros, I would buy a boat.",
        prompt: "WIN",
        keyword: "unreal past",
        answers: [ "won" ],
        times_done: 10,
        times_correct: 7
      )
    end

    before do
      # Seed an incorrect distractor row to verify analytics table rendering loops
      dossier_question.wrong_answers.create!(answer_text: "win", count: 3)

      # Seed a conversation thread comment to verify the forum block
      Comment.create!(commentable: dossier_question, user: admin_user, body: "Should we accept 'had won' here?")
    end

    it "renders the puzzle blueprint details, success ratio meters, common mistakes table, and forum comments thread" do
      get "/questions/#{dossier_question.id}"

      expect(response).to have_http_status(:ok)

      # Verify Core Puzzle Layout Elements compile beautifully
      expect(response.body).to include("Puzzle Blueprint Details")
      expect(response.body).to include("If I * a million euros")
      expect(response.body).to include("unreal past")

      # Verify Secure Answer Keys are visible on the Admin HTTP dashboard layer
      expect(response.body).to include('"won"')

      # Verify Analytics Performance components calculate percentages on screen
      expect(response.body).to include("Success Ratio")
      expect(response.body).to include("70.0%")
      expect(response.body).to include('"win"')

      expect(response.body).to include("Student Discussion Thread")
      expect(response.body).to include("Should we accept 'had won' here?")
    end
  end

  # =========================================================================
  # 4. GLOBAL LAYOUT FRAMEWORK MATRIX TEST
  # =========================================================================
  describe "Global Navbar Integrity Matrix" do
    before do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin_user)
    end

    it "proves the Home text link is gone, the username is active, and it targets the updated Dashboard label" do
      get "/questions"

      expect(response).to have_http_status(:ok)

      # Assert that the branding link exists but the duplicate text link was removed
      expect(response.body).to include("Rennlad Academy")
      expect(response.body).not_to include('>Home</a>')

      # Assert that the new text labels and username dropdown compile onto the layout tree
      expect(response.body).to include(admin_user.username)
      expect(response.body).to include("Dashboard")
      expect(response.body).not_to include("Command Station")
      expect(response.body).to include("Notifications")
    end
  end
end
