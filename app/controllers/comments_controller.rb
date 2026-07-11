# app/controllers/comments_controller.rb
class CommentsController < ApplicationController
  # Using standard Rails polymorphism to extract parent elements dynamically
  before_action :set_commentable, only: [ :create, :update ]

  def create
    @comment = @commentable.comments.new(comment_params)
    @comment.user = current_user
    @comment.commentable = @commentable

    # Threading Rule: Read the optional parent_id if replying to a thread
    if params[:parent_id].present?
      @comment.parent_id = params[:parent_id].to_i
    end

    if @comment.save
      flash[:notice] = "Comment has been created"
    else
      Rails.logger.info "Comment Validation Errors: #{@comment.errors.full_messages.join(', ')}"
      flash[:alert] = "Comment could not be created"
    end

    # POLYMORPHIC REDIRECT: Automatically routes to question_path or writing_path!
    redirect_to polymorphic_path(@commentable), status: :see_other
  end

  def update
    @comment = @commentable.comments.find(params[:id])

    if @comment.update(comment_params)
      flash[:notice] = "Comment has been updated"
    else
      flash[:alert] = "Comment could not be updated"
    end

    redirect_to polymorphic_path(@commentable), status: :see_other
  end

  def destroy
    @comment = Comment.find(params[:id])

    # ✅ Thread Safety: Trace up to find the root question/writing, even if this is a sub-reply
    root_target = @comment.commentable

    @comment.destroy
    flash[:notice] = "Comment has been moderated"

    redirect_to polymorphic_path(root_target), status: :see_other
  end

  private

  # CLEAN FINDER: Uses meta-programming to find parents without hardcoded ifs
  def set_commentable
    # Automatically extracts :question_id or :writing_id from the active path route parameters!
    resource, id = request.path.split("/")[1..2]
    @commentable = resource.singularize.classify.constantize.find(id)
  rescue
    flash[:alert] = "Target asset context not found."
    redirect_to root_path
  end

  def comment_params
    params.require(:comment).permit(:body)
  end
end
