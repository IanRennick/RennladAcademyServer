# spec/models/comment_spec.rb
# =========================================================================
# SYSTEM POLYMORPHIC COMMENT MODEL MATRIX SPEC
# - Stress-tests data integrity rules and text block boundary validations
# - Asserts relational cascading triggers purge nested sub-thread logs cleanly
# - Enforces strict anti-loop validation shields against self-referential rows
# =========================================================================
require "rails_helper"

RSpec.describe "Polymorphic Forum Comment System", type: :model do
  # --- Setup Shared Test Matrix Variables ---
  let!(:b2_level) { Level.find_or_create_by!(name: "B2") { |l| l.initial_rating = 1200 } }
  let!(:student) { User.create!(username: "forum_scholar", email: "forum@test.com", password: "password123", role: :student) }
  let!(:puzzle) { Question.create!(kind: :open_cloze, level: b2_level, main: "This is a prompt sentence.", answers: [ "test" ]) }

  # =========================================================================
  # 1. DATA INTEGRITY & STRUCTURE VALIDATIONS TESTS
  # =========================================================================
  describe "Data Integrity Validations & Loops Protection" do
    it "blocks comment creations containing blank content blocks" do
      blank_comment = Comment.new(user: student, commentable: puzzle, body: nil)
      expect(blank_comment).not_to be_valid
    end

    # =========================================================================
    # 2. CASCADING PURGE & THREAD SAFETY RELATIONSHIPS TESTS
    # =========================================================================
    it "cascades deletions down to nested child responses successfully" do
      parent = Comment.create!(user: student, commentable: puzzle, body: "Is this correct?")
      Comment.create!(user: student, commentable: puzzle, body: "Yes, fully verified.", parent: parent)

      expect {
        parent.destroy
      }.to change(Comment, :count).by(-2)
    end

    # =========================================================================
    # 3. SELF-REFERENTIAL ANTI-LOOP SHIELDS TESTS
    # =========================================================================
    it "blocks a comment record node from assigning its own ID as its parent" do
      comment = Comment.create!(user: student, commentable: puzzle, body: "Self validation loop try.")
      comment.parent_id = comment.id

      expect(comment).not_to be_valid
      expect(comment.errors[:parent_id]).to include("cannot form a self-referential loops index handle mapping context")
    end
  end
end
