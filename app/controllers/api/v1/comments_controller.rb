class Api::V1::CommentsController < ApiController
  before_action :find_commentable, only: [ :create ]
  before_action :set_and_authorize_comment, only: [ :update, :destroy ]

  # 1. POST /api/v1/comments (Create an entry or a nested reply)
  def create
    @comment = @commentable.comments.new(comment_params)
    @comment.user = current_user

    # Threading Rule: If parent_id is passed, map it to the parent thread
    if params[:parent_id].present?
      @comment.parent_id = params[:parent_id].to_i
    end

    if @comment.save
      render json: { message: "Comment created successfully", id: @comment.id }, status: :created
    else
      render json: { errors: @comment.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # Update comment
  def update
    if @comment.update(comment_params)
      render json: { message: "Comment updated successfully" }, status: :ok
    else
      render json: { errors: @comment.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # Destroy comment
  def destroy
    @comment.destroy
    head :no_content
  end

  private

  def comment_params
    params.require(:comment).permit(:body)
  end

  # Method for finding commentable object
  def find_commentable
    # React passes a clean payload structure like: { commentable_type: "Question", commentable_id: 12 }
    type = params[:commentable_type].to_s.classify
    if %w[Question Writing].include?(type) # Simply add your future models right inside this array!
      @commentable = type.constantize.find(params[:commentable_id])
    else
      render json: { error: "Invalid commentable type asset target parameter context." }, status: :bad_request
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Target asset resource not found." }, status: :not_found
  end

  # Mehtod for ensuring users can only edit or delete their own comments
  def set_and_authorize_comment
    @comment = Comment.find(params[:id])

    unless @comment.user == current_user
      render json: { error: "Unauthorized access profile scope constraint violation." }, status: :unauthorized
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Comment record match not found." }, status: :not_found
  end
end
