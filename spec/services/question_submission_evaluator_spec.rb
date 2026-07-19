# spec/services/question_submission_evaluator_spec.rb
# =========================================================================
# QUESTION SUBMISSION EVALUATOR SERVICE UNIT SPEC
# - Stress-tests atomic database transaction scoring parameters
# - Validates anti-Elo point farming guards and historical queue triggers
# =========================================================================
require "rails_helper"
require Rails.root.join("app/services/question_submission_evaluator.rb")

RSpec.describe QuestionSubmissionEvaluator, type: :service do
  # --- Setup Shared Test Matrix Variables ---
  let!(:b2_level) { Level.find_or_create_by!(name: "B2") { |l| l.initial_rating = 1200 } }
  let!(:student) { User.create!(username: "eval_scholar", email: "eval@test.com", password: "password123", role: :student, rating: 1200) }

  let!(:puzzle) do
    Question.create!(
      kind: :open_cloze,
      subtype: :oc_preposition,
      level: b2_level,
      main: "He is brilliant * languages.",
      answers: [ "at" ]
    )
  end

  describe "#call Core Evaluation Metrics & Security Guards" do
    context "with a standard fully correct submission" do
      it "increments question totals, advances global student Elo, and flags historical rows safely" do
        evaluator = QuestionSubmissionEvaluator.new(
          question: puzzle,
          user: student,
          submitted_raw: "  AT  ", # Verifies whitespace trimming
          mode: "standard"
        ).call

        # 1. Verify JSON output structure for React frontend parameters
        expect(evaluator.result_packet[:fully_correct]).to eq(true)
        expect(evaluator.result_packet[:score]).to eq(1.0)
        expect(evaluator.result_packet[:elo_change]).to be > 0

        # 2. Verify database-level metrics increments
        student.reload
        puzzle.reload
        expect(student.rating).to be > 1200
        expect(puzzle.times_done).to eq(1)
        expect(puzzle.times_correct).to eq(1)

        # 3. Verify history queue states: fully correct on first try skips review flags
        history = student.user_histories.find_by(question_id: puzzle.id)
        expect(history).not_to be_nil
        expect(history.first_attempt_correct).to eq(true)
        expect(history.needs_review).to eq(false)
      end
    end

    context "with an incorrect submission" do
      it "records the mistake inside distractor logs and moves the item into the student active review queue" do
        evaluator = QuestionSubmissionEvaluator.new(
          question: puzzle,
          user: student,
          submitted_raw: "in",
          mode: "standard"
        ).call

        expect(evaluator.result_packet[:fully_correct]).to eq(false)
        expect(evaluator.result_packet[:score]).to eq(0.0)

        # 1. Verify Common Distractors counter loops increment cleanly
        puzzle.reload
        distractor = puzzle.wrong_answers.find_by(answer_text: "in")
        expect(distractor).not_to be_nil
        expect(distractor.count).to eq(1)

        # 2. Verify Review Queue tracking targets
        student.reload
        history = student.user_histories.find_by(question_id: puzzle.id)
        expect(history.first_attempt_correct).to eq(false)
        expect(history.needs_review).to eq(true)
        expect(history.original_wrong_answer).to eq("in")
      end
    end

    context "under the Anti-Elo Point Farming Shield" do
      it "blocks rating inflation but logs metadata metrics safely if a student re-submits a past solved puzzle" do
        # Seed an explicit past victory to activate the anti-farming shield
        student.user_histories.create!(question: puzzle, first_attempt_correct: true, needs_review: false)

        # Advance user baseline Elo manually to set a baseline comparison check
        student.update!(rating: 1350)

        evaluator = QuestionSubmissionEvaluator.new(
          question: puzzle,
          user: student,
          submitted_raw: "at",
          mode: "standard"
        ).call

        expect(evaluator.result_packet[:already_solved]).to eq(true)
        expect(evaluator.result_packet[:elo_change]).to eq(0)

        # Student rating remains completely frozen from points-farming tricks
        student.reload
        expect(student.rating).to eq(1350)

        # But question counts continue to increment for accurate stock logs
        puzzle.reload
        expect(puzzle.times_done).to eq(1)
      end
    end
  end
end
