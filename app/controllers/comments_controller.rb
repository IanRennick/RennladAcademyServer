class CommentsController < ApplicationController
  before_action :set_commentable

  def create
    @comment = Comment.new(comment_params)
    @comment.user = current_user
    @comment.commentable = @commentable

    if @comment.save
      flash[:notice] = "Comment has been created"
    else
      flash[:alert] = "Comment has not been created"
    end

    if params[:commentable_type] === "writing"
      redirect_to writing_path(@commentable)

    elsif params[:commentable_type] === "question"
      redirect_to question_path(@commentable)
    end
  end

  def destroy
    @comment = Comment.find(params[:id])
    commentable_type = @comment.commentable_type
    commentable = @comment.commentable
    @comment.destroy

    if commentable_type === "Writing"
      redirect_to writing_path(commentable)

    elsif commentable_type === "Question"
      redirect_to question_path(commentable)
    end
  end


  def update
    @comment = @commentable.comments.find(params[:id])

    if @comment.update(comment_params)
      flash[:notice] = "Comment has been updated"
    else
      flash[:alert] = "Comment has not been updated"
    end

    if params[:commentable_type] === "writing"
      redirect_to writing_path(@commentable)

    elsif params[:commentable_type] === "question"
      redirect_to question_path(@commentable)
    end
  end


  private

  def set_commentable
    if params[:commentable_type] === "writing"
      @commentable = Writing.find(params[:writing_id])

    elsif params[:commentable_type] === "question"
      @commentable = Question.find(params[:question_id])
    end
  end

  def comment_params
    params.require(:comment).permit(:body)
  end
end
