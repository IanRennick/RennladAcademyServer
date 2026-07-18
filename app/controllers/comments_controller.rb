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
      # ✅ NEW SPRINT TRIGGER: Handle real-time forum notifications after saving successfully!
      if @comment.parent_id.present?
        parent_comment = Comment.find_by(id: @comment.parent_id)

        # 🛡️ SAFETY SHIELD: Never send an alert if a user is replying to their own text thread!
        if parent_comment && parent_comment.user_id != current_user.id
          Notification.create!(
            recipient_id: parent_comment.user_id,
            actor: current_user,
            event_type: "comment_reply",
            params: {
              "message" => "replied to your discussion thread",
              "text_snippet" => @comment.body.to_s.truncate(35),
              "url" => polymorphic_path(@commentable)
            }
          )
        end
      else
        # If it's a brand new root comment on a grammar puzzle, alert your active Admin pool!
        User.where(role: :admin).where.not(id: current_user.id).each do |admin_user|
          Notification.create!(
            recipient: admin_user,
            actor: current_user,
            event_type: "new_question_comment",
            params: {
              "message" => "posted a query on puzzle ##{@commentable.id}",
              "text_snippet" => @comment.body.to_s.truncate(35),
              "url" => polymorphic_path(@commentable)
            }
          )
        end
      end

      flash[:notice] = "Comment has been created"
    else
      Rails.logger.info "Comment Validation Errors: #{@comment.errors.full_messages.join(', ')}"
      flash[:alert] = "Comment could not be created"
    end

    # POLYMORPHIC REDIRECT: Automatically routes back to your beautiful question_path or writing_path!
    redirect_to polymorphic_path(@commentable), status: :see_other
  end

  def update
    comment = Comment.find(params[:id])

    if current_user.nil? || comment.user_id != current_user.id
      return render json: { error: "Unauthorized profile action blocked." }, status: :unauthorized
    end

    if comment.update(comment_params)
      render json: { message: "Comment updated successfully", id: comment.id }, status: :ok
    else
      render json: { errors: comment.errors.full_messages }, status: :unprocessable_entity
    end
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
