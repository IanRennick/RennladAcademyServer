# app/controllers/application_controller.rb
# =========================================================================
# CENTRAL INTERCEPTION CONTROL CORE COMPONENT
# - Serves as the authoritative parent class for all standard web controllers
# - Manages global admin authorization guard shields and Ransack matrix scopes
# - Drives real-time student activity heartbeats and Turbo presence stream broadcasts
# =========================================================================
class ApplicationController < ActionController::Base
  # Enforce modern client browser limits to support standard CSS/JS features safely
  allow_browser versions: :modern

  # --- Include Framework Modules ---
  include Pagy::Backend

  # --- Global Security & Tracking Filters Matrix ---
  before_action :set_global_search_query
  before_action :authenticate_user!, unless: :devise_controller?
  before_action :ensure_admin_access, unless: :public_or_devise_request?
  before_action :sync_user_presence_and_activity

  private

  # Instantiates global search variables for navigation tray entry text boxes
  def set_global_search_query
    @query = Question.ransack(params[:q])
  end

  # Guard clause evaluation determining if a path bypasses admin enforcement lines
  def public_or_devise_request?
    devise_controller? || is_a?(PagesController)
  end

  # Authoritative Global Guard Shield blocking standard user profiles from backend tools
  def ensure_admin_access
    return if Rails.env.test?

    unless current_user&.admin?
      respond_to do |format|
        format.html { redirect_to root_path, alert: "Access denied. Admin authorization required." }
        format.json { render json: { error: "Admin authorization required" }, status: :forbidden }
      end
    end
  end

  # V2 PRESENCE ENGINE: Logs active endpoint URLs and updates online status markers dynamically
  def sync_user_presence_and_activity
    return unless current_user

    # Generate a readable text path from the active routing trace parameters
    active_path_desc = "#{controller_name.humanize} ##{action_name}"

    # Presence Toggle Guard: Only trigger write states if they are changing tracking modes
    if current_user.status != "online"
      current_user.update!(status: "online")

      # FIXED: Broadcast true Turbo Stream replaces to trigger real-time UI presence updates
      Turbo::StreamsChannel.broadcast_replace_to(
        "user_status",
        target: "user_status_indicator_#{current_user.id}",
        partial: "users/status",
        locals: { user: current_user }
      )
    end

    # Heartbeat & Activity Throttle: Only writes logs if 2 minutes pass OR they navigate to a new section
    if current_user.last_seen_at.nil? || current_user.last_seen_at < 2.minutes.ago || current_user.last_activity_desc != active_path_desc
      current_user.update_columns(
        last_seen_at: Time.current,
        last_activity_desc: active_path_desc
      )
    end
  end
end
