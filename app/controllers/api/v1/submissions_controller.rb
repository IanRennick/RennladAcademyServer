# app/controllers/api/v1/submissions_controller.rb
class Api::V1::SubmissionsController < ApiController
  before_action :authenticate_api_user!
  before_action :set_and_authorize_submission, only: [ :show, :update ]

  # GET /api/v1/submissions
  def index
    submissions = current_user.student_submissions.includes(:prompt, :corrector).order(updated_at: :desc)

    render json: submissions.map { |s| serialize_submission(s) }, status: :ok
  end

  # GET /api/v1/submissions/:id
  def show
    render json: serialize_submission(@submission, include_comments: true), status: :ok
  end

  # POST /api/v1/submissions (React uses this to save drafts or submit entries)
  def create
    prompt = Prompt.find(params[:prompt_id])
    submission = current_user.student_submissions.new(
      prompt: prompt,
      student_payload: params[:student_payload],
      status: params[:status] == "submitted" ? :submitted : :draft
    )

    if submission.save
      prompt.increment!(:attempts_count) if submission.submitted?
      render json: { message: "Submission entry recorded cleanly", id: submission.id }, status: :created
    else
      render json: { errors: submission.errors.full_messages }, status: :unprocessable_content
    end
  end

  # PATCH/PUT /api/v1/submissions/:id (React uses this for autosave loops)
  def update
    if @submission.draft?
      new_status = params[:status] == "submitted" ? :submitted : :draft

      if @submission.update(student_payload: params[:student_payload], status: new_status)
        @submission.prompt.increment!(:attempts_count) if @submission.submitted?
        render json: { message: "Draft update cache synchronized cleanly" }, status: :ok
      else
        render json: { errors: @submission.errors.full_messages }, status: :unprocessable_content
      end
    else
      render json: { error: "Immutable row tracking violation: cannot mutate a submitted or corrected task." }, status: :bad_request
    end
  end

  private

  def set_and_authorize_submission
    @submission = Submission.find(params[:id])
    unless @submission.submitter_id == current_user.id
      render json: { error: "Unauthorized profile data view barrier violation." }, status: :unauthorized
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Submission record node not found." }, status: :not_found
  end

  def serialize_submission(submission, include_comments: false)
    data = {
      id: submission.id,
      prompt_title: submission.prompt.title,
      prompt_type: submission.prompt.prompt_type,
      status: submission.status,
      student_payload: submission.student_payload,
      final_result: submission.final_result,
      scores: submission.scores,
      teacher_feedback_html: submission.teacher_feedback&.to_s, # Formatted HTML for React rendering
      corrector_name: submission.corrector&.username,
      timestamp: submission.updated_at.strftime("%b %d, %Y")
    }

    if include_comments
      data[:comments] = submission.comments.includes(:user).map do |c|
        { id: c.id, author: c.user.username, body: c.body, created_at: c.created_at.strftime("%b %d, %H:%M") }
      end
    end

    data
  end
end
