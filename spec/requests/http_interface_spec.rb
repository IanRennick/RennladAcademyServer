require 'rails_helper'

RSpec.describe "HTTP Admin Interface System", type: :request do
  include Devise::Test::IntegrationHelpers
  include Pagy::Frontend

  let!(:b2_level) { Level.find_or_create_by!(name: "B2") { |l| l.initial_rating = 1200 } }
  let!(:admin_user) { User.create!(username: "head_teacher", email: "admin@academy.com", password: "password123", password_confirmation: "password123") }

  before do
    # ✅ FIX: Signs in the mock admin before the requests execute, passing through the shield!
    sign_in admin_user
  end

  before do
    26.times do |i|
      Question.create!(
        kind: :open_cloze,
        level: b2_level,
        main: "This is test question number #{i}.",
        answers: [ "test" ]
      )
    end
  end

  describe "GET /questions (The Command Center)" do
    it "renders the analytics dashboard, filters, and paginates rows to exactly 25 items" do
      sign_in admin_user

      get "/questions"

      expect(response).to have_http_status(:ok)

      # Avoid ampersand escaping bugs by matching a safe, clean slice of the heading text
      expect(response.body).to include("Database Analytics Dashboard")
      expect(response.body).to include("Filter Engine")

      expect(response.body).to include("This is test question number 25.")
      expect(response.body).to_not include("This is test question number 0.")

      expect(response.body).to include("class=\"page-item\"")
    end
  end

  describe "GET /users/:id (The Student Profile Dashboard)" do
    it "renders the multi-dimensional Elo metrics, CEFR accuracy tracker, and comments feed" do
      sign_in admin_user

      question_item = Question.first
      admin_user.user_histories.create!(question: question_item, first_attempt_correct: true, needs_review: false)
      Comment.create!(commentable: question_item, user: admin_user, body: "I am confused about this specific tag mapping parameter.")

      # Use user_path helper to automatically find the exact mapped routing configuration pathway
      get user_path(admin_user)

      expect(response).to have_http_status(:ok)

      expect(response.body).to include("CEFR Tier Accuracy")
      expect(response.body).to include("Target Review Areas")
      expect(response.body).to include("Recent Student Doubts")
      expect(response.body).to include("I am confused about this specific tag mapping parameter.")
    end
  end

  describe "GET /questions/:id (The Puzzle Dossier Board)" do
    let!(:b2_level) { Level.find_or_create_by!(name: "B2") { |l| l.initial_rating = 1200 } }
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
      # Seed an incorrect distractor row to verify your analytics table rendering loop
      dossier_question.wrong_answers.create!(answer_text: "win", count: 3)
      
      # Seed a root conversation thread comment starter to verify the forum block
      Comment.create!(commentable: dossier_question, user: admin_user, body: "Should we accept 'had won' here?")
    end

    it "renders the puzzle blueprint details, success ratio meters, common mistakes table, and forum comments thread" do
      # Execute the page load request
      get "/questions/#{dossier_question.id}"

      expect(response).to have_http_status(:ok)
      
      # 1. Verify Core Puzzle Layout Elements compile beautifully
      expect(response.body).to include("Puzzle Blueprint Details")
      expect(response.body).to include("If I * a million euros")
      expect(response.body).to include("unreal past")
      
      # 2. Verify Secure Answer Keys are visible on the Admin HTTP dashboard layer
      expect(response.body).to include('"won"')
      
      # 3. Verify Analytics Performance components calculate percentages on screen
      expect(response.body).to include("Success Ratio")
      expect(response.body).to include("70.0%") # Math check: (7 / 10) * 100
      expect(response.body).to include('"win"')  # Verifies the incorrect distractor row shows up
      
      # 4. Verify Active Forum Stream components render successfully
      expect(response.body).to include("Student Discussion Thread")
      expect(response.body).to include("Should we accept 'had won' here?")
    end
  end
end
