# spec/requests/api/v1/questions_spec.rb
require "rails_helper"

RSpec.describe "Stateless API V1 Curriculum Gateway Matrix", type: :request do
  include Devise::Test::IntegrationHelpers

  # --- Setup Shared Test Matrix Variables ---
  let!(:b2_level) { Level.find_or_create_by!(name: "B2") { |l| l.initial_rating = 1200 } }
  let!(:student_user) { User.create!(username: "api_scholar", email: "api@test.com", password: "password123", role: :student) }

  let!(:puzzle) do
    Question.create!(
      kind: :multiple_choice,
      subtype: :mc_phrasal,
      level: b2_level,
      main: "Look * the text.",
      options: [ "at", "on", "in" ],
      answers: [ "at" ]
    )
  end

  before do
    allow_any_instance_of(Api::V1::QuestionsController).to receive(:current_user).and_return(student_user)
  end

  describe "GET /api/v1/questions/:id" do
    it "successfully parses the record, invokes the serializer, and returns integer enums" do
      get "/api/v1/questions/#{puzzle.id}"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json["id"]).to eq(puzzle.id)
      expect(json["kind"]).to eq(0) # multiple_choice resolves back to its integer token mapping
      expect(json["options"]).to match_array([ "at", "on", "in" ])
    end
  end

  describe "GET /api/v1/questions/random" do
    it "resolves criteria filters accurately and returns a single matching question row" do
      get "/api/v1/questions/random", params: { level: "b2", type: "0" }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["id"]).to eq(puzzle.id)
    end

    it "safely triggers a 404 error packet when search parameter bounds evaluate empty" do
      get "/api/v1/questions/random", params: { level: "C2" }

      expect(response).to have_http_status(:not_found)
      json = JSON.parse(response.body)
      expect(json["error"]).to include("No questions found matching criteria")
    end
  end
end
