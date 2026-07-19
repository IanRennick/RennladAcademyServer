class NotificationsController < ApplicationController
  # POST /notifications/mark_all_as_read
  def mark_all_as_read
    current_user.notifications.unread.update_all(read_at: Time.current)

    respond_to do |format|
      # Force a clean layout reload so the bell icon instantly locks into its disabled state!
      format.turbo_stream { render turbo_stream: turbo_stream.action(:reload, "") rescue redirect_back(fallback_location: root_path) }
      format.html { redirect_back fallback_location: root_path }
    end
  end

  # POST /notifications/:id/toggle_read
  def toggle_read
    notification = current_user.notifications.find(params[:id])

    if notification.read_at.nil?
      notification.update!(read_at: Time.current)
    else
      notification.update!(read_at: nil)
    end

    unread_count = current_user.notifications.unread.count

    respond_to do |format|
      if unread_count.zero?
        # If no unread alerts remain, reload the page structure to smoothly lock the bell dropdown shut
        format.turbo_stream { render turbo_stream: turbo_stream.action(:reload, "") rescue redirect_back(fallback_location: root_path) }
        format.html { redirect_back fallback_location: root_path }
      else
        # If there are still items left in the queue, process the individual row update asynchronously
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace(notification, partial: "notifications/notification", locals: { notification: notification }),
            turbo_stream.replace("nav-notification-badge", html: "
              <span id='nav-notification-badge' class='position-absolute badge rounded-pill bg-danger' style='font-size: 0.62rem; padding: 0.25em 0.4em; top: 3px; right: -3px; z-index: 10;'>
                #{unread_count}
              </span>
            ".html_safe)
          ]
        end
        format.html { redirect_back fallback_location: root_path }
      end
    end
  end
end
