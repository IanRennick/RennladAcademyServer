# spec/requests/api/v1/reports_spec.rb
# =========================================================================
# STATELESS API V1 REPORTS INGESTION PIPELINE SPEC
# - Stress-tests token-isolated report creations passing validation limits
# - Asserts parameter requirements block corrupt or blank inputs
# - Verifies automated background system alerts fire into admin notification logs
# =========================================================================
require "rails_helper"

RSpec.describe "Stateless API V1 Reports Ingestion Matrix", type: :request do
  include Devise::Test::IntegrationHelpers

  # --- Setup Shared Test Matrix Variables ---
  let!(:b2_level) { Level.find_or_create_by!(name: "B2") { |l| l.initial_rating = 1200 } }
  let!(:admin_teacher) { User.create!(username: "api_moderator", email: "teacher@academy.com", password: "password123", role: :admin) }
  let!(:student_user) { User.create!(username: "api_scholar", email: "student@academy.com", password: "password123", role: :student) }
  let!(:puzzle) { Question.create!(kind: :open_cloze, level: b2_level, main: "This is a grammar core sentence.", answers: [ "test" ]) }

  before do
    # Bind our authentication helper mock directly to the targeted API controller thread instance
    allow_any_instance_of(Api::V1::ReportsController).to receive(:current_user).and_return(student_user)
  end

  # =========================================================================
  # 1. SUCCESSFUL INGESTION & NOTIFICATION DISPATCH TEST
  # =========================================================================
  describe "POST /api/v1/reports" do
    context "with valid parameters" do
      it "successfully builds a report row and dispatches alert records to admins" do
        expect {
          post "/api/v1/reports", params: {
            report: {
              report_type: "typo",
              description: "The prompt text contains a subtle spelling mistake.",
              question_id: puzzle.id,
              url: "/questions/random"
            }
          }
        }.to change(Report, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["message"]).to eq("Report logged successfully")

        # Verify that our admin account received the automated notification trigger safely
        # Note: 2 counts accounts for user signup notification PLUS this bug report alert
        expect(admin_teacher.notifications.unread.count).to eq(2)
        expect(admin_teacher.notifications.last.params["message"]).to include("submitted a fresh typo ticket")
      end
    end

    # =========================================================================
    # 2. VALIDATION BARRIER PARAMETER INTERCEPTIONS TEST
    # =========================================================================
    context "with invalid parameters" do
      it "intercepts blank descriptions and returns an unprocessable content status payload" do
        expect {
          post "/api/v1/reports", params: {
            report: {
              report_type: "ui_bug",
              description: "Short" # Too short! (Minimum 10 characters required)
            }
          }
        }.not_to change(Report, :count)

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json["errors"].first).to include("Description is too short")
      end
    end
  end
end
