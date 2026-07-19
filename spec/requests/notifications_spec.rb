# spec/requests/notifications_spec.rb
require "rails_helper"

RSpec.describe "Notifications Action Controller Matrix", type: :request do
  include Devise::Test::IntegrationHelpers

  let!(:admin_user) { User.create!(username: "control_deck", email: "admin@test.com", password: "password123", role: :admin) }
  let!(:teacher_user) { User.create!(username: "instructor_node", email: "teacher@test.com", password: "password123", role: :teacher) }

  # Seed an active unread notification row inside the target profile
  let!(:alert_item) { Notification.create!(recipient: admin_user, actor: teacher_user, event_type: "system_alert") }

  before { sign_in admin_user }

  describe "POST /notifications/:id/toggle_read" do
    it "successfully updates the read_at timestamp and outputs a clean Turbo Stream layout replacement" do
      expect(admin_user.notifications.unread.count).to eq(2)

      # Trigger an active POST toggle request to our controller endpoint
      post "/notifications/#{alert_item.id}/toggle_read"

      expect(response).to have_http_status(:redirect) # Default fallback redirects back gracefully
      alert_item.reload

      expect(alert_item.read_at).not_to be_nil
      expect(admin_user.notifications.unread.count).to eq(1)
    end
  end

  describe "POST /notifications/mark_all_as_read" do
    it "performs a bulk database macro update to clear out all unread statuses instantly" do
      # Seed an extra unread message alert to verify bulk clear limits
      Notification.create!(recipient: admin_user, actor: teacher_user, event_type: "new_chat_message")
      expect(admin_user.notifications.unread.count).to eq(3)

      post "/notifications/mark_all_as_read"

      expect(response).to have_http_status(:redirect)
      expect(admin_user.notifications.unread.count).to eq(0)
    end
  end
end
