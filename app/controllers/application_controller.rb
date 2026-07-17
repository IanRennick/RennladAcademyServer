class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :set_query
  # 1. GLOBAL ADMIN SHIELD: Blocks everyone from HTTP views unless logged in as an admin
  before_action :authenticate_user!
  before_action :ensure_admin_access

  # 2. ⚡ ACTIVITY & PRESENCE TRACKER: Logs heartbeats and updates online states
  before_action :sync_user_presence_and_activity

  # Incorporate Pagy's backend calculator methods
  include Pagy::Backend


  def set_query
    @query = Question.ransack(params[:q])
  end


  private

  def ensure_admin_access
    # If a user tries to load any standard HTML page and isn't an admin, kick them out
    unless current_user&.admin?
      # For API safety, if it's an API request we return a 403, otherwise redirect
      if request.format.json?
        render json: { error: "Admin authorization required" }, status: :forbidden
      else
        redirect_to root_path, alert: "Access denied. Admin authorization required."
      end
    end
  end

  def sync_user_presence_and_activity
    return unless current_user

    # ✅ PRESENCE GUARD: Only touch the DB if they aren't already marked online!
    if current_user.status != "online"
      current_user.update!(status: User.statuses[:online])

      # Broadcast the live update to your WebSocket channels instantly
      ActionCable.server.broadcast("appearance_channel", {
        user_id: current_user.id,
        status: "online"
      })
    end

    # ✅ HEARTBEAT GUARD: Only update the timestamp if it's been idle for 2+ minutes
    if current_user.last_seen_at.nil? || current_user.last_seen_at < 2.minutes.ago
      current_user.update_column(:last_seen_at, Time.current)
    end
  end
end
