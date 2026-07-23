# spec/requests/api/v3_comprehensive_spec.rb
# =========================================================================
# STATELESS API V3 AND ADMINISTRATIVE PIPELINE INTEGRATION SPEC
# - Stress-tests API prompt retrieval matrices and serialized JSON responses
# - Verifies student submission create/update operations for drafts/submissions
# - Confirms administrative HTTP view controllers successfully compile average grades
# =========================================================================
require "rails_helper"

RSpec.describe "Version 3 Comprehensive Architecture Suite Matrix", type: :request do
  include Devise::Test::IntegrationHelpers

  # --- Setup Shared Test Matrix Variables ---
  let!(:b2_level) { Level.find_or_create_by!(name: "B2") { |l| l.initial_rating = 1200 } }
  let!(:student) { User.create!(username: "api_scholar", email: "student@academy.com", password: "password123", role: :student) }
  let!(:teacher) { User.create!(username: "master_tutor", email: "teacher@academy.com", password: "password123", role: :admin) }

  let!(:writing_task) do
    Prompt.create!(
      level: b2_level, prompt_type: "writing", title: "Technology Essay", topic: "science",
      metadata: { "situation" => "Write an essay.", "assignment_type" => "essay" }
    )
  end

  before do
    # Authenticate actions context pools cleanly
    allow_any_instance_of(ApiController).to receive(:current_user).and_return(student)
  end

  # =========================================================================
  # 1. STATELESS API INGESTION ROUTING TESTS
  # =========================================================================
  describe "Stateless API Endpoints Interface Matrix" do
    it "GET /api/v1/prompts outputs clean json containing variable metadata" do
      get "/api/v1/prompts"
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.first["title"]).to eq("Technology Essay")
      expect(json.first["situation"]).to eq("Write an essay.")
    end

    it "POST /api/v1/submissions records student drafts into the pipeline" do
      expect {
        post "/api/v1/submissions", params: { prompt_id: writing_task.id, student_payload: "My introductory hook statement sentence.", status: "draft" }
      }.to change(Submission, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(Submission.last.status).to eq("draft")
    end
  end

  # =========================================================================
  # 2. ADMINISTRATIVE WEB PANEL ACTIONS TESTS
  # =========================================================================
  describe "Administrative HTTP Dashboard Interaction Interface" do
    before do
      # Sign in admin teacher account profile context cleanly to pass devise blocks
      sign_in teacher
    end

    it "PATCH /admin/dashboard/submissions/:id calculates scores and alerts student" do
      active_submission = Submission.create!(prompt: writing_task, submitter: student, status: :submitted, student_payload: "Essay content.")

      patch "/admin/dashboard/submissions/#{active_submission.id}", params: {
        scores: { "grammar" => "5", "vocabulary" => "4", "coherence" => "3", "task_achievement" => "4" },
        teacher_feedback: "Excellent complex clauses usage patterns."
      }

      expect(response).to redirect_to(admin_submissions_path)
      active_submission.reload

      expect(active_submission.status).to eq("corrected")
      expect(active_submission.final_result).to eq(4.0) # (5+4+3+4) / 4 = 4.0 average score
      expect(student.notifications.unread.count).to eq(1)
    end
  end
end
