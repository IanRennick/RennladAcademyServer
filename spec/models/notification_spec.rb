# spec/models/notification_spec.rb
require "rails_helper"

RSpec.describe Notification, type: :model do
  describe "Polymorphic Notification Core System" do
    let(:recipient_user) { User.create!(username: "notified_student", email: "student_notif@test.com", password: "password123") }
    let(:actor_user) { User.create!(username: "acting_admin", email: "admin_actor@test.com", password: "password123", role: :admin) }

    it "successfully creates notification records with flexible parameters and scopes unread rows accurately" do
      expect {
        Notification.create!(
          recipient: recipient_user,
          actor: actor_user,
          event_type: "comment_reply",
          params: { "message" => "replied to your discussion thread", "url" => "/questions/1" }
        )
      }.to change(Notification, :count).by(1)

      notification = Notification.last
      expect(notification.recipient).to eq(recipient_user)
      expect(notification.actor).to eq(actor_user)
      expect(notification.event_type).to eq("comment_reply")
      expect(notification.params["message"]).to eq("replied to your discussion thread")

      # ✅ Verify scopes track unread states correctly
      expect(Notification.unread.count).to eq(1)
      notification.update!(read_at: Time.current)
      expect(Notification.unread.count).to eq(0)
    end
  end
end
