# app/controllers/prompts_controller.rb
class PromptsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin_access

  def new
    @prompt = Prompt.new
  end

  def create
    # Extract metadata components from standard parameters layout structure
    metadata_payload = {
      "situation" => params[:situation],
      "assignment_type" => params[:assignment_type],
      "word_count" => params[:word_count],
      "question" => params[:question],
      "bullet_points" => params[:bullet_points].to_s.split(",").map(&:strip),
      "instructions" => params[:instructions].to_s.split(";").map(&:strip)
    }.compact_blank

    @prompt = Prompt.new(
      level_id: params[:prompt][:level_id],
      prompt_type: params[:prompt][:prompt_type],
      title: params[:prompt][:title],
      topic: params[:prompt][:topic].to_s.downcase.strip,
      metadata: metadata_payload
    )

    @prompt.photo.attach(params[:prompt][:photo]) if params[:prompt][:photo].present?

    if @prompt.save
      flash[:notice] = "Task prompt successfully registered inside the curriculum pool inventory."
      redirect_to admin_dashboard_path
    else
      flash[:alert] = "Failed to create prompt: #{@prompt.errors.full_messages.join(', ')}"
      render :new
    end
  end

  def destroy
    prompt = Prompt.find(params[:id])
    prompt.destroy
    flash[:notice] = "Task prompt purged cleanly from data stores."
    redirect_to admin_dashboard_path
  end
end
