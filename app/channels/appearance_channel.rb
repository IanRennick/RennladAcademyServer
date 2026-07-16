class AppearanceChannel < ApplicationCable::Channel
  def subscribed
    stream_from "appearance_channel"
    # Mark user online automatically upon opening the websocket connection link
    set_user_status(:online)
  end

  def unsubscribed
    set_user_status(:offline)
  end

  def online
    set_user_status(:online)
  end

  def away
    set_user_status(:away)
  end

  def offline
    set_user_status(:offline)
  end

  private

  def set_user_status(status_string)
    status_integer = User.statuses[status_string]

    # ✅ PERFORMANCE FIX: Only touch the DB if the status actually changed!
    if current_user.status != status_string
      current_user.update!(status: status_integer)

      # ✅ REACT COMPATIBILITY FIX: Broadcast a clean JSON notification event
      # along with your legacy Hotwire view updates
      ActionCable.server.broadcast("appearance_channel", {
        user_id: current_user.id,
        username: current_user.username,
        status: status_string
      })
    end
  end
end
