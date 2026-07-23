# spec/models/submission_spec.rb
# =========================================================================
# UNIFIED SUBMISSION SCORING SCHEMA UNIT SPEC
# - Stress-tests 4-category writing constraints and 5-category speaking rules
# - Asserts validation barriers block incomplete scores upon correction cycles
# =========================================================================
require "rails_helper"

RSpec.describe "Unified Submission & Grading System", type: :model do
  # --- Setup Shared Test Matrix Variables ---
  let!(:b2_level) { Level.find_or_create_by!(name: "B2") { |l| l.initial_rating = 1200 } }
  let!(:student) { User.create!(username: "exam_student", email: "exam@test.com", password: "password123", role: :student) }
  let!(:teacher) { User.create!(username: "exam_teacher", email: "teacher@test.com", password: "password123", role: :teacher) }

  let!(:writing_prompt) do
    Prompt.create!(
      level: b2_level, prompt_type: "writing", title: "Essay Task", topic: "general",
      metadata: { "situation" => "Write an essay.", "assignment_type" => "essay" }
    )
  end

  let!(:speaking_prompt) do
    Prompt.create!(
      level: b2_level, prompt_type: "speaking", title: "Photo Task", topic: "general",
      metadata: { "image_url" => "https://test.jpg", "question" => "Speak about this." }
    )
  end

  # =========================================================================
  # 1. MULTI-CATEGORY SCORE MATRIX TESTS
  # =========================================================================
  describe "Variable Criteria Category Grading Shields" do
    it "allows a writing task to save with exactly 4 valid categories upon correction" do
      submission = Submission.new(
        prompt: writing_prompt,
        submitter: student,
        corrector: teacher,
        status: :corrected,
        student_payload: "My B2 Essay...", final_result: 4.0,
        scores: { "grammar" => 4, "vocabulary" => 4, "coherence" => 4, "task_achievement" => 4 }
      )
      expect(submission).to be_valid
    end

    it "allows a speaking task to save with exactly 5 valid categories upon correction" do
      submission = Submission.new(
        prompt: speaking_prompt,
        submitter: student,
        corrector: teacher,
        status: :corrected,
        student_payload: "audio_clip_token", final_result: 4.5,
        scores: { "grammar" => 5, "vocabulary" => 4, "coherence" => 4, "pronunciation" => 5, "interactive_style" => 4 }
      )
      expect(submission).to be_valid
    end

    it "blocks correction status transitions if required scores are missing or out of bounds" do
      bad_grading = Submission.new(
        prompt: writing_prompt,
        submitter: student,
        corrector: teacher,
        status: :corrected,
        final_result: 3.0, scores: { "grammar" => 6, "vocabulary" => 0 }
      )
      expect(bad_grading).not_to be_valid
    end
  end
end
