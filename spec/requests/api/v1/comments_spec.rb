require 'rails_helper'

RSpec.describe "Api::V1::Comments Endpoints", type: :request do
  let!(:b2_level) { Level.find_or_create_by!(name: "B2") { |l| l.initial_rating = 1200 } }
  let!(:user) { User.create!(username: "api_commenter", email: "commenter@example.com", password: "password123") }

  # Create a second user to test unauthorized update/deletion access locks
  let!(:other_user) { User.create!(username: "hacker_bob", email: "bob@example.com", password: "password123") }

  let!(:question) do
    Question.create!(
      kind: :multiple_choice,
      subtype: :mc_phrasal,
      level: b2_level,
      main: "Bob decided to * up a new sport.",
      options: [ "give", "take" ],
      answers: [ "take" ]
    )
  end

  # Setup secure Doorkeeper Application token authorization contexts
  let!(:application) { Doorkeeper::Application.create!(name: "React Web App Client", redirect_uri: "urn:ietf:wg:oauth:2.0:oob", scopes: "public") }
  let!(:token) { Doorkeeper::AccessToken.create!(application_id: application.id, resource_owner_id: user.id, scopes: "public") }
  let!(:headers) { { "Authorization" => "Bearer #{token.token}" } }

  describe "POST /api/v1/comments" do
    context "when creating a brand new root comment thread starter" do
      it "returns a 201 created status and successfully builds the dynamic polymorphic record" do
        post "/api/v1/comments",
             params: { commentable_type: "Question", commentable_id: question.id, comment: { body: "Can someone clarify this tag?" } },
             headers: headers

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["message"]).to eq("Comment created successfully")

        created_comment = Comment.find(json["id"])
        expect(created_comment.commentable).to eq(question)
        expect(created_comment.parent_id).to be_nil
      end
    end

    context "when creating a nested reply to an existing comment thread" do
      it "binds the record properly to the designated parent_id element pointer" do
        root = Comment.create!(commentable: question, user: user, body: "Root query string text context.")

        post "/api/v1/comments",
             params: { commentable_type: "Question", commentable_id: question.id, parent_id: root.id, comment: { body: "Here is your answer!" } },
             headers: headers

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)

        reply = Comment.find(json["id"])
        expect(reply.parent_id).to eq(root.id)
      end
    end
  end

  describe "PATCH /api/v1/comments/:id" do
    let!(:user_comment) { Comment.create!(commentable: question, user: user, body: "Original sentence paragraph block text.") }

    context "when the true author attempts to modify their own comment" do
      it "successfully updates the body and returns a 200 ok code status" do
        patch "/api/v1/comments/#{user_comment.id}", params: { comment: { body: "Updated comment layout text content." } }, headers: headers

        expect(response).to have_http_status(:ok)
        expect(user_comment.reload.body.to_s).to include("Updated comment layout text content.")
      end
    end
  end

  describe "DELETE /api/v1/comments/:id" do
    let!(:user_comment) { Comment.create!(commentable: question, user: user, body: "To be deleted text.") }

    it "allows the author to securely drop the record, returning a 204 no content payload statement" do
      delete "/api/v1/comments/#{user_comment.id}", headers: headers
      expect(response).to have_http_status(:no_content)
      expect(Comment.exists?(user_comment.id)).to be_falsey
    end
  end
end
