# app/controllers/api/v1/questions_controller.rb
# =========================================================================
# STATELESS API V1 CURRICULUM CORE PATHWAY CONTROLLER
# - Coordinates random topic draws, review queue extractions, and dossiers
# - Delegates answer grading workflows to QuestionSubmissionEvaluator service
# - Delegates raw payload transformations to QuestionSerializer engine
# =========================================================================
class Api::V1::QuestionsController < ApiController
  # --- Action Lifecycle Filters ---
  before_action :authenticate_api_user!, only: [ :review_queue ]

  # --- Action Endpoints ---

  # GET /api/v1/questions/random
  def random
    questions = Question.all

    # 1. Primary Category Axis Filter
    if params[:type].present?
      type_param = params[:type]
      resolved_type = type_param.match?('\A\d+\z') ? Question.kinds.key(type_param.to_i) : type_param

      if resolved_type.present? && Question.kinds.has_key?(resolved_type.to_s)
        questions = questions.where(kind: resolved_type)
      else
        questions = Question.none
      end
    end

    # 2. Subtype Grammar Axis Filter
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

    # 4. CEFR Difficulty Tier Filter
    if params[:level].present?
      questions = questions.joins(:level).where(levels: { name: params[:level].to_s.strip.upcase })
    end

    @question = questions.order("RANDOM()").first

    if @question
      render json: QuestionSerializer.new(@question).as_json, status: :ok
    else
      render json: { error: "No questions found matching criteria" }, status: :not_found
    end
  end

  # GET /api/v1/questions/:id
  def show
    @question = Question.find(params[:id])
    render json: QuestionSerializer.new(@question).as_json, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Question not found" }, status: :not_found
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
