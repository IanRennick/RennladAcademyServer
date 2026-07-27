# app/services/question_submission_evaluator.rb
# =========================================================================
# STATELESS CURRICULUM QUESTION SUBMISSION & METRICS EVALUATION SERVICE
# - Encapsulates all backend multi-part scoring and Elo calculations
# - Runs within an atomic SQL database transaction block to prevent data racing
# - Updates global inventory logs, fine-grained stats enums, and history feeds
# =========================================================================
class QuestionSubmissionEvaluator
  attr_reader :question, :user, :submitted_raw, :is_practice_mode, :result_packet

  def initialize(question:, user:, submitted_raw:, mode:)
    @question = question
    @user = user
    @submitted_raw = submitted_raw.to_s.strip
    @is_practice_mode = mode.to_s.strip.downcase == "practice"
    @result_packet = {}
  end

  def call
    ActiveRecord::Base.transaction do
      process_evaluation_metrics
      compute_elo_adjustments
      commit_question_aggregates
      commit_user_metrics_matrix if user.present?
      compile_response_packet
    end
    self
  end

  private

  def process_evaluation_metrics
    @score = question.score_flat_submission(submitted_raw)
    @is_fully_correct = (@score == 1.0)
    @is_any_credit_earned = (@score > 0.0)

    @has_past_win = user.present? && user.user_histories.exists?(question_id: question.id, correct_on_any_attempt: true)
    @effective_practice = is_practice_mode || @has_past_win
  end

  def compute_elo_adjustments
    @old_user_rating = user.present? ? user.rating : 1200
    @old_q_rating = question.rating

    if user.present?
      stats_count = user.user_stats.where(stat_type: "kind").sum(:times_done).to_i
      user_total = stats_count.zero? ? 25 : stats_count

      q_done_count = question.times_done.to_i
      question_total = q_done_count.zero? ? 25 : q_done_count

      @new_global_user_elo, @new_global_q_elo = EloCalculator.calculate(
        user.rating, @old_q_rating, @score, user_total, question_total
      )
    end
  end

  def commit_question_aggregates
    question.increment!(:times_done)
    question.increment!(:times_correct) if @is_fully_correct
    question.update!(rating: @new_global_q_elo) if user.present?

    unless @is_fully_correct
      wrong_log = question.wrong_answers.find_or_initialize_by(answer_text: submitted_raw)
      wrong_log.new_record? ? wrong_log.update!(count: 1) : wrong_log.increment!(:count)
    end
  end

  def commit_user_metrics_matrix
    # A. Global Rating Updates
    user.update!(rating: @new_global_user_elo) unless @effective_practice

    # B. Puzzle Kind Enums Elo
    kind_int = Question.kinds[question.kind]
    kind_stat = user.user_stats.find_or_create_by!(stat_type: "kind", stat_key: kind_int)

    # Synchronized calculator arguments to maintain identical K-factors
    new_kind_elo, _ = EloCalculator.calculate(kind_stat.rating, @old_q_rating, @score, kind_stat.times_done, question.times_done.to_i)
    kind_stat.increment!(:times_done)
    kind_stat.increment!(:times_correct) if @is_fully_correct
    kind_stat.update!(rating: new_kind_elo) unless @effective_practice

    # C. Subtype Grammar Elo
    if question.subtype.present?
      subtype_int = Question.subtypes[question.subtype]
      subtype_stat = user.user_stats.find_or_create_by!(stat_type: "subtype", stat_key: subtype_int)

      # Synchronized calculator arguments to maintain identical K-factors
      new_sub_elo, _ = EloCalculator.calculate(subtype_stat.rating, @old_q_rating, @score, subtype_stat.times_done, question.times_done.to_i)
      subtype_stat.increment!(:times_done)
      subtype_stat.increment!(:times_correct) if @is_fully_correct
      subtype_stat.update!(rating: new_sub_elo) unless @effective_practice
    end

    # D. Multi-Dimensional Tag Analytics Caches
    if question.tags.any?
      if @effective_practice
        stat_record = user.user_tag_stat || user.create_user_tag_stat(stats_json: {})
        current_json = stat_record.stats_json.dup
        question.tags.map(&:name).each do |tag|
          current_json[tag] ||= { "done" => 0, "correct" => 0, "rating" => 1200 }
          current_json[tag]["done"] += 1
          current_json[tag]["correct"] += 1 if @is_fully_correct
        end
        stat_record.update!(stats_json: current_json)
      else
        user.update_tag_metrics(question.tags.map(&:name), @old_q_rating, @is_fully_correct)
      end
    end

    # E. Active Review Queues & History Logging
    history = user.user_histories.find_by(question_id: question.id)
    if history.nil?
      user.user_histories.create!(
        question_id: question.id,
        first_attempt_correct: @is_fully_correct,
        correct_on_any_attempt: @is_fully_correct, # Tracks absolute career completion flags cleanly
        needs_review: !@is_fully_correct,
        original_wrong_answer: @is_fully_correct ? nil : submitted_raw
      )
    else
      # If they eventually get it right on subsequent attempts, log their career win flag!
      updates = {}
      updates[:needs_review] = false if history.needs_review && @is_any_credit_earned
      updates[:correct_on_any_attempt] = true if @is_fully_correct
      history.update!(updates) if updates.any?
    end
  end

  def compile_response_packet
    @result_packet = {
      score: @score,
      fully_correct: @is_fully_correct,
      correct_answers: question.answers,
      user_new_rating: user.present? ? user.rating : 1200,
      elo_change: user.present? ? (user.rating - @old_user_rating) : 0,
      already_solved: @has_past_win
    }
  end
end
