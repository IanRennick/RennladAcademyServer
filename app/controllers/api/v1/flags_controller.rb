# app/controllers/api/v1/flags_controller.rb
class Api::V1::FlagsController < ApiController
  before_action :authenticate_api_user!

  # POST /api/v1/flags
  def create
    # Whitelist polymorphic string configurations securely
    type = params[:commentable_type].to_s.classify

    if %w[Question Writing Comment].include?(type)
      commentable_asset = type.constantize.find(params[:commentable_id])

      @flag = Flag.new(
        user: current_user,
        commentable: commentable_asset,
        report_type: params[:report_type],
        body: params[:body].to_s.strip,
        status: :open
      )

      if @flag.save
        render json: { message: "Asset flag logged successfully for administrator review.", id: @flag.id }, status: :created
      else
        render json: { errors: @flag.errors.full_messages }, status: :unprocessable_entity
      end
    else
      render json: { error: "Invalid flag commentable asset target type context." }, status: :bad_request
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Target asset resource not found." }, status: :not_found
  end
end
