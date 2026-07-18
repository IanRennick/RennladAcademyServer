class NotificationsController < ApplicationController
  # POST /notifications/mark_all_as_read
  def mark_all_as_read
    current_user.notifications.unread.update_all(read_at: Time.current)

    def mark_all_as_read
    current_user.notifications.unread.update_all(read_at: Time.current)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          # 1. ✅ NATIVE FIXED: Completely replaces the red badge container with a hidden, empty fallback tag!
          turbo_stream.replace("nav-notification-badge", html: '
            <span id="nav-notification-badge" class="position-absolute top-0 start-100 translate-middle badge rounded-pill bg-danger d-none" style="font-size: 0.65rem; padding: 0.25em 0.4em;">
              0
            </span>
          '.html_safe),

          # 2. Replaces the feed content stack with a clean, empty placeholder layout row
          turbo_stream.update("notifications_feed", html: '
            <li class="list-group-item bg-transparent text-muted text-center py-4 small" id="empty-notification-placeholder">
              📂 Clean slate! No new notifications.
            </li>
          '.html_safe)
          ]
        end
        format.html { redirect_back fallback_location: root_path }
      end
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
      format.turbo_stream do
        streams = [
          # Update the single row styling instantly
          turbo_stream.replace(notification, partial: "notifications/notification", locals: { notification: notification })
        ]

        # Dynamically calculate the navbar bell red badge counter values
        if unread_count.zero?
          streams << turbo_stream.add_class("d-none", target: "nav-notification-badge")
          streams << turbo_stream.replace("notifications_feed", html: '
            <ul class="list-group list-group-flush bg-transparent mb-0" id="notifications_feed">
              <li class="list-group-item bg-transparent text-muted text-center py-4 small" id="empty-notification-placeholder">
                📂 Clean slate! No new notifications.
              </li>
            </ul>
          ')
        else
          streams << turbo_stream.remove_class("d-none", target: "nav-notification-badge")
          streams << turbo_stream.update("nav-notification-badge", html: unread_count.to_s)
        end

        render turbo_stream: streams
      end
      format.html { redirect_back fallback_location: root_path }
    end
  end
end
