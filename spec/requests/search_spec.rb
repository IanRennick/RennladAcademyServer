# spec/requests/search_spec.rb
require "rails_helper"

RSpec.describe "Omni-Search Query Routing Matrix", type: :request do
  include Devise::Test::IntegrationHelpers

  let!(:b2_level) { Level.find_or_create_by!(name: "B2") { |l| l.initial_rating = 1200 } }
  let!(:admin_user) { User.create!(username: "head_teacher", email: "admin@academy.com", password: "password123", role: :admin) }
  let!(:target_student) { User.create!(username: "vocabulary_scholar", email: "scholar@test.com", password: "password123", role: :student) }

  let!(:matching_question) { Question.create!(kind: :open_cloze, level: b2_level, main: "He has a broad vocabulary.", answers: [ "test" ]) }

  before { sign_in admin_user }

  describe "GET /search" do
    it "returns matching relational entities when valid keyword parameters hit the controller" do
      # Simulate a unified text search hitting the multi-model engine
      get "/search", params: { search_term: "vocabulary" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("vocabulary_scholar")
      expect(response.body).to include("He has a broad vocabulary.")
    end

    it "safely triggers empty state fallbacks for user indices when search fields are left blank" do
      get "/search", params: { search_term: "" }

      expect(response).to have_http_status(:ok)
      # Verifies that the user section component card is skipped completely when blank
      expect(response.body).not_to include("Matching Student Profiles")
    end
  end
end
