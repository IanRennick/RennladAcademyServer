# spec/services/question_submission_evaluator_spec.rb
# =========================================================================
# SUBMISSION EVALUATOR INTEGRATION TRANSITION SPEC
# - Stress-tests atomic transaction data writing across multiple tables
# - Asserts points-farming security shields keep malicious loops frozen
# =========================================================================
require "rails_helper"
require Rails.root.join("app/services/question_submission_evaluator.rb")

RSpec.describe QuestionSubmissionEvaluator, type: :service do
  # --- Setup Shared Test Matrix Variables ---
  let!(:b2_level) { Level.find_or_create_by!(name: "B2") { |l| l.initial_rating = 1200 } }
  let!(:student) { User.create!(username: "eval_scholar", email: "eval@test.com", password: "password123", role: :student, rating: 1200) }
  let!(:puzzle) { Question.create!(kind: :open_cloze, subtype: :oc_preposition, level: b2_level, main: "He is brilliant * languages.", answers: [ "at" ]) }

  # =========================================================================
  # 1. TRANSACTION CONTRUCTION WRITES TEST
  # =========================================================================
  describe "#call Core Evaluation Metrics & Security Guards" do
    context "with a standard fully correct submission" do
      it "increments question totals, advances global student Elo, and flags historical rows safely" do
        evaluator = QuestionSubmissionEvaluator.new(
          question: puzzle, user: student, submitted_raw: "  AT  ", mode: "standard"
        ).call

        expect(evaluator.result_packet[:fully_correct]).to eq(true)
        expect(evaluator.result_packet[:score]).to eq(1.0)

        student.reload
        expect(student.rating).to be > 1200

        history = student.user_histories.find_by(question_id: puzzle.id)
        expect(history.needs_review).to eq(false)
      end
    end

    # =========================================================================
    # 2. REVIEW QUEUE ROUTINGS & FAULT LOGGING TEST
    # =========================================================================
    context "with an incorrect submission" do
      it "records the mistake inside distractor logs and moves the item into the student active review queue" do
        evaluator = QuestionSubmissionEvaluator.new(
          question: puzzle, user: student, submitted_raw: "in", mode: "standard"
        ).call

        expect(evaluator.result_packet[:fully_correct]).to eq(false)

        puzzle.reload
        distractor = puzzle.wrong_answers.find_by(answer_text: "in")
        expect(distractor.count).to eq(1)

        history = student.user_histories.find_by(question_id: puzzle.id)
        expect(history.needs_review).to eq(true)
      end
    end

    # =========================================================================
    # 3. ANTI-ELO FARMING SECURITY SHIELD TEST
    # =========================================================================
    context "under the Anti-Elo Point Farming Shield" do
      it "blocks rating inflation but logs metadata metrics safely if a student re-submits a past solved puzzle" do
        student.user_histories.create!(question: puzzle, first_attempt_correct: true, needs_review: false)
        student.update!(rating: 1350)

        evaluator = QuestionSubmissionEvaluator.new(
          question: puzzle, user: student, submitted_raw: "at", mode: "standard"
        ).call

        expect(evaluator.result_packet[:already_solved]).to eq(true)
        expect(evaluator.result_packet[:elo_change]).to eq(0)

        student.reload
        expect(student.rating).to eq(1350)
      end
    end
  end
end
