# spec/models/notification_spec.rb
require "rails_helper"

RSpec.describe "Real-Time Notification System", type: :model do
  let!(:teacher) { User.create!(username: "head_master", email: "teacher@test.com", password: "password123", role: :admin) }
  let!(:student) { User.create!(username: "diligent_learner", email: "student@test.com", password: "password123", role: :student) }

  describe "Data Integrity Guard Shields" do
    it "instantiates an empty parameters hash payload cleanly if none is specified" do
      notif = Notification.create!(recipient: student, actor: teacher, event_type: "system_alert")

      expect(notif).to be_valid
      expect(notif.params).to eq({})
    end

    it "strictly rejects illegal or unsupported event type token injections" do
      bad_notif = Notification.new(recipient: student, actor: teacher, event_type: "corrupt_junk_event")

      expect(bad_notif).not_to be_valid
      expect(bad_notif.errors[:event_type]).to include("corrupt_junk_event is not a valid, system-supported notification event type token")
    end

    it "blocks notifications where the system actor is the exact same record entity as the recipient" do
      illegal_loop = Notification.new(recipient: student, actor: student, event_type: "system_alert")

      expect(illegal_loop).not_to be_valid
      expect(illegal_loop.errors[:recipient_id]).to include("cannot represent the same profile index entity as the target event actor")
    end
  end
end
