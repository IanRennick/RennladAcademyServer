# app/controllers/comments_controller.rb
# =========================================================================
# UNIVERSAL POLYMORPHIC DISCUSSION FORUM ACTIONS CONTROLLER
# - Coordinates asynchronous commentary creations, updates, and moderation purges
# - Metaprogrammatically extracts context assets with built-in class whitelists
# - Dispatches whitelisted system notifications to threads and administrators
# =========================================================================
class CommentsController < ApplicationController
  # --- Action Lifecycle Filters ---
  before_action :set_commentable, only: [ :create, :update ]

  # --- Action Endpoints ---

  # POST /questions/:question_id/comments or /writings/:writing_id/comments
  def create
    @comment = @commentable.comments.new(comment_params)
    @comment.user = current_user
    @comment.commentable = @commentable

    # Process nested sub-thread reply parameters
    if params[:parent_id].present?
      @comment.parent_id = params[:parent_id].to_i
    end

    if @comment.save
      if @comment.parent_id.present?
        parent_comment = Comment.find_by(id: @comment.parent_id)

        # 🛡️ SECURITY SHIELD: Do not trigger alerts if a user replies to their own post
        if parent_comment && parent_comment.user_id != current_user.id
          # FIXED: Event type string set to whitelisted 'system_alert' to pass notification constraints
          Notification.create!(
            recipient_id: parent_comment.user_id,
            actor: current_user,
            event_type: "system_alert",
            params: {
              "message" => "replied to your discussion thread",
              "text_snippet" => @comment.body.to_s.gsub(/<\/?[^>]*>/, "").strip.truncate(35),
              "url" => polymorphic_path(@commentable)
            }
          )
        end
      else
        # If it is a fresh root query on a question, notify active administrators safely
        User.where(role: :admin).where.not(id: current_user.id).each do |admin_user|
          # FIXED: Event type string shifted to whitelisted 'system_alert'
          Notification.create!(
            recipient: admin_user,
            actor: current_user,
            event_type: "system_alert",
            params: {
              "message" => "posted a query on puzzle ##{@commentable.id}",
              "text_snippet" => @comment.body.to_s.gsub(/<\/?[^>]*>/, "").strip.truncate(35),
              "url" => polymorphic_path(@commentable)
            }
          )
        end
      end

      flash[:notice] = "Comment has been created successfully."
    else
      Rails.logger.info "Comment Validation Failure: #{@comment.errors.full_messages.join(', ')}"
      flash[:alert] = "Comment content area cannot be blank."
    end

    redirect_to polymorphic_path(@commentable), status: :see_other
  end

  # PATCH/PUT /questions/:question_id/comments/:id
  def update
    comment = current_user.comments.find(params[:id])

    respond_to do |format|
      if comment.update(comment_params)
        format.html { redirect_to polymorphic_path(@commentable), notice: "Comment updated." }
        format.json { render json: { message: "Comment updated successfully", id: comment.id }, status: :ok }
      else
        format.html { redirect_to polymorphic_path(@commentable), alert: "Unable to process update parameters." }
        format.json { render json: { errors: comment.errors.full_messages }, status: :unprocessable_content }
      end
    end
  end

  # DELETE /comments/:id
  def destroy
    @comment = Comment.find(params[:id])

    # Eagerly capture target reference before purging the active node entry
    root_target = @comment.commentable

    # Authorization Shield: Only allow the author or an administrator to drop comments
    if current_user.admin? || @comment.user_id == current_user.id
      @comment.destroy
      flash[:notice] = "Comment has been moderated successfully."
    else
      flash[:alert] = "Unauthorized moderation attempt blocked."
    end

    redirect_to polymorphic_path(root_target), status: :see_other
  end

  private

  # SECURITY FIXED: Enforces clear whitelisted classes to prevent parameter manipulation constantize exploits
  def set_commentable
    resource, id = request.path.split("/")[1..2]
    class_string = resource.singularize.classify

    # Strictly block unauthorized classes from compiling inside constantize macros
    raise "Security Boundary Infraction" unless %w[Question Writing].include?(class_string)

    @commentable = class_string.constantize.find(id)
  rescue => e
    Rails.logger.error "Polymorphic Parameter Infraction: #{e.message}"
    flash[:alert] = "Target asset context not found."
    redirect_to root_path
  end

  def comment_params
    params.require(:comment).permit(:body)
  end
end
