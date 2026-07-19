# app/controllers/notifications_controller.rb
# =========================================================================
# REAL-TIME NOTIFICATIONS DISPATCH CONTROLLER
# - Coordinates database toggle states and bulk asynchronous read macros
# - Drives real-time Hotwire Turbo Stream payload replacements for navbar elements
# =========================================================================
class NotificationsController < ApplicationController
  # --- Action Endpoint Controllers ---

  # POST /notifications/mark_all_as_read
  def mark_all_as_read
    # Bulk update macro executed efficiently at the SQL level to maximize performance
    current_user.notifications.unread.update_all(read_at: Time.current)

    respond_to do |format|
      # Forces a clean layout reload so the global navbar bell icon resets instantly
      format.turbo_stream { render turbo_stream: turbo_stream.action(:reload, "") rescue redirect_back(fallback_location: root_path) }
      format.html { redirect_back fallback_location: root_path }
    end
  end

  # POST /notifications/:id/toggle_read
  def toggle_read
    # Scoped database lookup prevents cross-user authorization bypass attacks
    notification = current_user.notifications.find(params[:id])

    if notification.read_at.nil?
      notification.update!(read_at: Time.current)
    else
      notification.update!(read_at: nil)
    end

    unread_count = current_user.notifications.unread.count

    respond_to do |format|
      if unread_count.zero?
        format.turbo_stream { render turbo_stream: turbo_stream.action(:reload, "") rescue redirect_back(fallback_location: root_path) }
        format.html { redirect_back fallback_location: root_path }
      else
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace(notification, partial: "notifications/notification", locals: { notification: notification }),
            # Replaced raw hardcoded HTML text blocks with a clean, decoupled view partial hook
            turbo_stream.replace("nav-notification-badge", partial: "notifications/badge", locals: { unread_count: unread_count })
          ]
        end
        format.html { redirect_back fallback_location: root_path }
      end
    end
  end
end
