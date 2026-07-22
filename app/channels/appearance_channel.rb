# app/channels/appearance_channel.rb
# =========================================================================
# REAL-TIME SYSTEM PRESENCE STREAMING CHANNEL
# - Coordinates websocket state transitions (online, away, offline)
# - Updates user state indices inside atomic execution guards
# - Synchronizes both raw JSON payloads (for React) and Turbo Stream replacements (for views)
# =========================================================================
class AppearanceChannel < ApplicationCable::Channel
  # --- Action Entry Event Loops ---

  def subscribed
    stream_from "appearance_channel"
    set_user_status("online")
  end

  def unsubscribed
    set_user_status("offline")
  end

  def online
    set_user_status("online")
  end

  def away
    set_user_status("away")
  end

  def offline
    set_user_status("offline")
  end

  private

  # Centralized tracking updater that coordinates multi-platform broadcasts
  def set_user_status(status_string)
    # Performance Guard: Skip processing if the user's status hasn't actually shifted
    if current_user.status != status_string
      current_user.update!(status: status_string)

      # A. REACT FRONTEND PAYLOAD CHANNEL
      # Broadcasts a clean, lightweight JSON packet optimized for SPA state management
      ActionCable.server.broadcast("appearance_channel", {
        user_id: current_user.id,
        username: current_user.username,
        status: status_string
      })

      # B. LEGACY WEB LAYOUT TURBO STREAM CHANNEL
      # Dynamically replaces presence indicator elements inside the web navigation sidebars
      Turbo::StreamsChannel.broadcast_replace_to(
        "user_status",
        target: "user_status_indicator_#{current_user.id}",
        partial: "users/status",
        locals: { user: current_user }
      )
    end
  end
end
