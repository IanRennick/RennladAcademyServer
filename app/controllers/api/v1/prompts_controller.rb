# app/controllers/api/v1/prompts_controller.rb
class Api::V1::PromptsController < ApiController
  before_action :authenticate_api_user!

  # GET /api/v1/prompts?type=writing&level=B2
  def index
    prompts = Prompt.includes(:level).all
    prompts = prompts.where(prompt_type: params[:type]) if params[:type].present?

    if params[:level].present?
      level_record = Level.find_by(name: params[:level].upcase)
      prompts = prompts.where(level: level_record) if level_record
    end

    serialized = prompts.map { |p| serialize_prompt(p) }
    render json: serialized, status: :ok
  end

  # GET /api/v1/prompts/:id
  def show
    prompt = Prompt.find(params[:id])
    render json: serialize_prompt(prompt), status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Prompt index match not found." }, status: :not_found
  end

  private

  def serialize_prompt(prompt)
    {
      id: prompt.id,
      level: prompt.level.name,
      prompt_type: prompt.prompt_type,
      title: prompt.title,
      topic: prompt.topic,
      attempts_count: prompt.attempts_count,
      # Safely outputs chaotic writing blocks or short speaking questions out of JSONB metadata
      situation: prompt.situation,
      word_count: prompt.word_count,
      bullet_points: prompt.bullet_points,
      instructions: prompt.instructions,
      assignment_type: prompt.assignment_type,
      question: prompt.question,
      photo_url: prompt.photo.attached? ? rails_blob_url(prompt.photo, only_path: true) : prompt.metadata["image_url"]
    }
  end
end
