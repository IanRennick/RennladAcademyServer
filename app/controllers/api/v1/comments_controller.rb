# app/controllers/api/v1/comments_controller.rb
# =========================================================================
# STATELESS API V1 POLYMORPHIC DISCUSSION FEEDS CONTROLLER
# - Inherits from ApiController to ensure token-isolated forum extractions
# - Processes nested sub-thread reply parameters via client JSON payloads
# - Dispatches whitelisted system notifications to threads and administrators
# =========================================================================
class Api::V1::CommentsController < ApiController
  # --- Action Lifecycle Filters Matrix ---
  before_action :authenticate_api_user!
  before_action :find_commentable, only: [ :create ]
  before_action :set_and_authorize_comment, only: [ :update, :destroy ]

  # --- Action Endpoints ---

  # POST /api/v1/comments
  def create
    @comment = @commentable.comments.new(comment_params)
    @comment.user = current_user

    # Threading Rule: If parent_id is passed, map it to the parent thread
    if params[:parent_id].present?
      @comment.parent_id = params[:parent_id].to_i
    end

    if @comment.save
      # DISPATCH SYNCHRONIZATION OAUTH LAYER NOTIFICATIONS
      if @comment.parent_id.present?
        parent_comment = Comment.find_by(id: @comment.parent_id)

        if parent_comment && parent_comment.user_id != current_user.id
          Notification.create!(
            recipient_id: parent_comment.user_id,
            actor: current_user,
            event_type: "system_alert",
            params: {
              "message" => "replied to your discussion thread",
              "text_snippet" => @comment.body.to_s.gsub(/<\/?[^>]*>/, "").strip.truncate(35),
              "url" => "/questions/#{@commentable.id}"
            }
          )
        end
      else
        # If it's a fresh root query on a puzzle, notify administrators safely
        User.where(role: :admin).where.not(id: current_user.id).each do |admin_user|
          Notification.create!(
            recipient: admin_user,
            actor: current_user,
            event_type: "system_alert",
            params: {
              "message" => "posted a query on puzzle ##{@commentable.id}",
              "text_snippet" => @comment.body.to_s.gsub(/<\/?[^>]*>/, "").strip.truncate(35),
              "url" => "/questions/#{@commentable.id}"
            }
          )
        end
      end

      render json: { message: "Comment created successfully", id: @comment.id }, status: :created
    else
      render json: { errors: @comment.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/v1/comments/:id
  def update
    if @comment.update(comment_params)
      render json: { message: "Comment updated successfully" }, status: :ok
    else
      render json: { errors: @comment.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/comments/:id
  def destroy
    @comment.destroy
    head :no_content
  end

  private

  def comment_params
    params.require(:comment).permit(:body)
  end

  # Extracts polymorphic parent assets cleanly using a rigid class whitelist string array
  def find_commentable
    type = params[:commentable_type].to_s.classify

    if %w[Question Writing].include?(type)
      @commentable = type.constantize.find(params[:commentable_id])
    else
      render json: { error: "Invalid commentable type asset target parameter context." }, status: :bad_request
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Target asset resource not found." }, status: :not_found
  end

  # Enforces a strict session security barrier to block cross-user edit or delete attempts
  def set_and_authorize_comment
    @comment = Comment.find(params[:id])

    unless @comment.user_id == current_user.id
      render json: { error: "Unauthorized access profile scope constraint violation." }, status: :unauthorized
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Comment record match not found." }, status: :not_found
  end
end
