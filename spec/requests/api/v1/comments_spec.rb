# spec/requests/api/v1/comments_spec.rb
# =========================================================================
# STATELESS API V1 POLYMORPHIC DISCUSSION ENDPOINTS SPEC
# - Asserts asynchronous JSON-based commentary injections commit safely
# - Verifies strict ownership barrier checks prevent cross-user mutations
# =========================================================================
require "rails_helper"

RSpec.describe "Stateless API V1 Comments Request Pipeline Matrix", type: :request do
  include Devise::Test::IntegrationHelpers

  # --- Setup Shared Test Matrix Variables ---
  let!(:b2_level) { Level.find_or_create_by!(name: "B2") { |l| l.initial_rating = 1200 } }
  let!(:admin_teacher) { User.create!(username: "api_moderator", email: "teacher@academy.com", password: "password123", role: :admin) }
  let!(:student_user) { User.create!(username: "api_scholar", email: "student@academy.com", password: "password123", role: :student) }
  let!(:other_student) { User.create!(username: "api_lurker", email: "lurker@academy.com", password: "password123", role: :student) }
  let!(:puzzle) { Question.create!(kind: :open_cloze, level: b2_level, main: "This is a grammar sample sentence context.", answers: [ "test" ]) }

  before do
    allow_any_instance_of(Api::V1::CommentsController).to receive(:current_user).and_return(student_user)
  end

  # =========================================================================
  # 1. POLYMORPHIC JSON PAYLOAD CONVERSION TEST
  # =========================================================================
  describe "POST /api/v1/comments" do
    context "with valid parameters" do
      it "successfully builds a polymorphic comment row and dispatches alert records to admins" do
        expect {
          post "/api/v1/comments", params: {
            commentable_type: "Question",
            commentable_id: puzzle.id,
            comment: { body: "Is this a compound relative clause structure?" }
          }
        }.to change(Comment, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["message"]).to eq("Comment created successfully")
        expect(admin_teacher.notifications.unread.count).to eq(3)
      end
    end
  end

  # =========================================================================
  # 2. PROFILE SECURITY OWNERSHIP SEGREGATIONS TEST
  # =========================================================================
  describe "DELETE /api/v1/comments/:id" do
    it "strictly blocks a different user from deleting someone else's comment text" do
      target_comment = Comment.create!(user: student_user, commentable: puzzle, body: "A private comment area.")

      allow_any_instance_of(Api::V1::CommentsController).to receive(:current_user).and_return(other_student)

      delete "/api/v1/comments/#{target_comment.id}"

      expect(response).to have_http_status(:unauthorized)
      json = JSON.parse(response.body)
      expect(json["error"]).to include("Unauthorized access profile scope constraint violation")
    end
  end
end
