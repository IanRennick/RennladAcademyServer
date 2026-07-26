# app/controllers/api/v1/questions_controller.rb
# =========================================================================
# STATELESS API V1 CURRICULUM CORE PATHWAY CONTROLLER
# =========================================================================
# - Coordinates random topic draws, review queue extractions, and dossiers.
# - Delegates answer grading workflows to QuestionSubmissionEvaluator service.
# - Delegates raw payload transformations to QuestionSerializer engine.
# =========================================================================
class Api::V1::QuestionsController < ApiController
  # --- Action Lifecycle Filters ---
  before_action :authenticate_api_user!, only: [ :review_queue, :submit_answer ]

  # --- Action Endpoints ---

  # GET /api/v1/questions/random
  def random
    questions = Question.all

    # =========================================================================
    # 0. BACKGROUND WEAKNESS FILTER GATING
    # Intercepts the query early if weakness tracking mode is active.
    # Evaluates their UserTagStat JSON and filters the pool down to those 5 tags.
    # =========================================================================
    if params[:mode] == "weakness" && current_user
      tag_stat = current_user.user_tag_stat

      if tag_stat.present?
        # Fetch the top 5 weakest categories array strings from the model helper
        weak_tags = tag_stat.top_weak_categories(5)

        if weak_tags.present?
          # Filter the questions database pool to match those specific problem tags
          questions = questions.joins(:tags).where(tags: { name: weak_tags })
        end
      end
    end

    # 1. Primary Category Axis Filter
    if params[:kind].present?
      kind_param = params[:kind]

      # Resolve string keys or integers smoothly against your enum blueprint mapping
      resolved_kind = kind_param.match?('\A\d+\z') ? Question.kinds.key(kind_param.to_i) : kind_param

      if resolved_kind.present? && Question.kinds.has_key?(resolved_kind.to_s)
        questions = questions.where(kind: resolved_kind)
      else
        questions = Question.none
      end
    end

    # 2. Subtype Grammar Axis Filter (e.g., mc_phrasal, oc_preposition)
    if params[:subtype].present?
      subtype_param = params[:subtype]
      resolved_subtype = subtype_param.match?('\A\d+\z') ? Question.subtypes.key(subtype_param.to_i) : subtype_param

      if resolved_subtype.present? && Question.subtypes.has_key?(resolved_subtype.to_s)
        questions = questions.where(subtype: resolved_subtype)
      else
        questions = Question.none
      end
    end

    # 3. Metadata Tag Selector Filter
    if params[:tag].present?
      questions = questions.joins(:tags).where(tags: { name: params[:tag].to_s.strip.downcase })
    end

    # 4. CEFR Difficulty Tier Filter (e.g., B2, C1)
    if params[:level].present?
      questions = questions.joins(:level).where(levels: { name: params[:level].to_s.strip.upcase })
    end

    # Grab one random question from your completely filtered criteria pool
    @question = questions.order("RANDOM()").first

    # --- AUTOMATED CRASH PROTECTION FALLBACK ---
    # If the weakness tag filter yielded zero matching questions under these joint filters,
    # fallback gracefully to a standard random question matching just the raw layout format constraints.
    if @question.nil? && params[:mode] == "weakness"
      fallback_questions = Question.all
      fallback_questions = fallback_questions.where(kind: resolved_kind) if params[:kind].present? && resolved_kind.present?
      fallback_questions = fallback_questions.where(subtype: resolved_subtype) if params[:subtype].present? && resolved_subtype.present?
      fallback_questions = fallback_questions.joins(:level).where(levels: { name: params[:level].to_s.strip.upcase }) if params[:level].present?

      @question = fallback_questions.order("RANDOM()").first
    end

    if @question
      # Render using your native serialization logic engine cleanly
      render json: QuestionSerializer.new(@question).as_json, status: :ok
    else
      render json: { error: "No questions found matching criteria" }, status: :not_found
    end
  end

  # GET /api/v1/questions/review_queue
  def review_queue
    wrong_questions = Question.joins(:user_histories)
                              .where(user_histories: { user_id: current_user.id, needs_review: true })
                              .includes(:tags)

    formatted_queue = wrong_questions.map { |q| QuestionSerializer.new(q).as_json }
    render json: formatted_queue, status: :ok
  end

  # POST /api/v1/questions/:id/submit_answer
  def submit_answer
    @question = Question.find(params[:id])

    service = QuestionSubmissionEvaluator.new(
      question: @question,
      user: current_user,
      submitted_raw: params[:answer],
      mode: params[:mode]
    ).call

    render json: service.result_packet, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Question not found" }, status: :not_found
  end
end