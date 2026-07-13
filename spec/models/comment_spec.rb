require 'rails_helper'

RSpec.describe Comment, type: :model do
  # Setup valid baseline items to satisfy database and uniqueness constraints
  let!(:b2_level) { Level.find_or_create_by!(name: "B2") { |l| l.initial_rating = 1200 } }
  let!(:user) { User.create!(username: "forum_student", email: "student@example.com", password: "password123") }
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

  describe "self-referencing thread associations" do
    it "successfully structures a nested conversation tree layout" do
      # 1. Create a root thread starter comment
      root_comment = Comment.create!(
        commentable: question,
        user: user,
        body: "Is 'take up' correct here?"
      )

      # 2. Create a child reply comment pointing to the root parent
      reply_comment = Comment.create!(
        commentable: question,
        user: user,
        parent: root_comment, # Links the self-reference parent pointer column
        body: "Yes, because it means starting a hobby!"
      )

      expect(root_comment.parent_id).to be_nil
      expect(root_comment.replies).to include(reply_comment)
      expect(reply_comment.parent).to eq(root_comment)
      expect(reply_comment.parent_id).to eq(root_comment.id)
    end

    it "safely triggers a cascading delete on all nested replies if the parent comment is deleted" do
      root_comment = Comment.create!(commentable: question, user: user, body: "Root text message body context.")
      Comment.create!(commentable: question, user: user, parent: root_comment, body: "Reply message context.")

      expect(Comment.count).to eq(2)

      # Act: Deleting the root thread should wipe out sub-replies automatically via dependent: :destroy
      root_comment.destroy
      expect(Comment.count).to eq(0)
    end
  end
end
