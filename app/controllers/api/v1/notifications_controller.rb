# app/controllers/api/v1/notifications_controller.rb
# =========================================================================
# STATELESS API V1 STUDENT ALERTS & NOTIFICATIONS CONTROLLER
# - Inherits from ApiController to mandate secure OAuth bearer token parsing
# - Compiles unified real-time alert logs and counts for the React navbar
# - Executes bulk database clearing macros under strict ownership parameters
# =========================================================================
class Api::V1::NotificationsController < ApiController
  # --- Action Lifecycle Filters Matrix ---
  before_action :authenticate_api_user!
  before_action :set_and_authorize_notification, only: [ :update ]

  # --- Action Endpoints ---

  # GET /api/v1/notifications
  def index
    # Gather notifications belonging explicitly to the token owner, eager loading actors
    all_notifications = current_user.notifications.includes(:actor).order(created_at: :desc)
    unread_notifications = all_notifications.unread

    # Serialize rows into clean JSON layout fragments optimized for frontend badges
    serialized_list = all_notifications.map do |notif|
      {
        id: notif.id,
        event_type: notif.event_type,
        actor: notif.actor&.username || "System",
        message: notif.params&.dig("message").to_s,
        text_snippet: notif.params&.dig("text_snippet").to_s,
        url: notif.params&.dig("url").to_s,
        timestamp: notif.created_at.strftime("%b %d, %H:%M"),
        read: notif.read_at.present?
      }
    end

    render json: {
      unread_count: unread_notifications.count,
      notifications: serialized_list
    }, status: :ok
  end

  # PATCH/PUT /api/v1/notifications/:id
  def update
    # If already read, revert back to unread; if unread, mark as read now
    if @notification.read_at.present?
      @notification.update!(read_at: nil)
    else
      @notification.update!(read_at: Time.current)
    end

    render json: { message: "Notification state toggled successfully", read: @notification.read_at.present? }, status: :ok
  end

  # POST /api/v1/notifications/mark_all_as_read
  def mark_all_as_read
    # Performs a high-speed database macro write across the student's unread collection
    current_user.notifications.unread.update_all(read_at: Time.current)

    render json: { message: "All notifications cleared successfully", unread_count: 0 }, status: :ok
  end

  private

  # Enforces a strict session security barrier to block cross-user edit attempts
  def set_and_authorize_notification
    @notification = Notification.find(params[:id])

    unless @notification.recipient_id == current_user.id
      render json: { error: "Unauthorized access profile scope constraint violation." }, status: :unauthorized
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Notification record match not found." }, status: :not_found
  end
end
