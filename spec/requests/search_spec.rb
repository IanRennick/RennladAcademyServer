# spec/requests/search_spec.rb
# =========================================================================
# OMNI-SEARCH MULTI-MODEL ROUTER ENDPOINT SPEC
# - Validates text keyword parameter matching pipelines across different schemas
# - Verifies that blank queries safely fall back to empty array collections
# =========================================================================
require "rails_helper"

RSpec.describe "Omni-Search Query Routing Matrix", type: :request do
  include Devise::Test::IntegrationHelpers

  # --- Setup Shared Test Matrix Variables ---
  let!(:b2_level) { Level.find_or_create_by!(name: "B2") { |l| l.initial_rating = 1200 } }
  let!(:admin_user) { User.create!(username: "head_teacher", email: "admin@academy.com", password: "password123", role: :admin) }
  let!(:target_student) { User.create!(username: "vocabulary_scholar", email: "scholar@test.com", password: "password123", role: :student) }
  let!(:matching_question) { Question.create!(kind: :open_cloze, level: b2_level, main: "He has a broad vocabulary.", answers: [ "test" ]) }

  before { sign_in admin_user }

  # =========================================================================
  # 1. MULTI-MODEL SEARCH INGESTION PARSING TEST
  # =========================================================================
  describe "GET /search" do
    it "returns matching relational entities when valid keyword parameters hit the controller" do
      get "/search", params: { q: { main_or_prompt_or_keyword_or_options_as_text_or_answers_as_text_or_tags_name_i_cont_any: "vocabulary" } }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Matching Student Profiles")
      expect(response.body).to include("He has a broad vocabulary.")
    end

    it "safely triggers empty state fallbacks for user indices when search fields are left blank" do
      get "/search", params: { q: { main_or_prompt_or_keyword_or_options_as_text_or_answers_as_text_or_tags_name_i_cont_any: "" } }

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("Matching Student Profiles")
    end
  end
end
