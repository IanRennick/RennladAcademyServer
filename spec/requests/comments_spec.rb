# spec/requests/comments_spec.rb
require "rails_helper"

RSpec.describe "Polymorphic Comments Request Pipeline Matrix", type: :request do
  include Devise::Test::IntegrationHelpers

  let!(:b2_level) { Level.find_or_create_by!(name: "B2") { |l| l.initial_rating = 1200 } }
  let!(:admin_teacher) { User.create!(username: "forum_moderator", email: "teacher@academy.com", password: "password123", role: :admin) }
  let!(:student_user) { User.create!(username: "curious_scholar", email: "student@academy.com", password: "password123", role: :student) }

  let!(:puzzle) { Question.create!(kind: :open_cloze, level: b2_level, main: "This is a grammar sample sentence context.", answers: [ "test" ]) }

  before { sign_in student_user }

  describe "POST /questions/:question_id/comments" do
    context "with valid parameters" do
      it "successfully builds a polymorphic comment thread and notifies the admin pool" do
        expect {
          post "/questions/#{puzzle.id}/comments", params: { comment: { body: "Can we clarify the preposition rule used here?" } }
        }.to change(Comment, :count).by(1)

        expect(response).to redirect_to(question_path(puzzle))
        expect(flash[:notice]).to eq("Comment has been created successfully.")

        # Verify that our admin account received the whitelisted notification record safely
        expect(admin_teacher.notifications.unread.count).to eq(2)
        expect(admin_teacher.notifications.last.event_type).to eq("system_alert")
      end
    end

    context "with an invalid blank comment body payload" do
      it "prevents creation loops and sets a validation alert flash message" do
        expect {
          post "/questions/#{puzzle.id}/comments", params: { comment: { body: "" } }
        }.not_to change(Comment, :count)

        expect(response).to redirect_to(question_path(puzzle))
        expect(flash[:alert]).to eq("Comment content area cannot be blank.")
      end
    end
  end
end
