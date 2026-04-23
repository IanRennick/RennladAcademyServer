class CommentsController < ApplicationController
  before_action :set_writing

  def create
    @comment = @writing.comments.create(comment_params)
    @comment.user = current_user

    if @comment.save
      flash[:notice] = "Comment has been created"
      redirect_to writing_path(@writing)
    else
      flash[:alert] = "Comment has not been created"
      redirect_to writing_path(@writing)
    end
  end

  def destroy
    @comment = @writing.comments.find(params[:id])
    @comment.destroy
    redirect_to writing_path(@writing)
  end



  private

  def set_writing
    @writing = Writing.find(params[:writing_id])
  end

  def comment_params
    params.require(:comment).permit(:body)
  end
end
