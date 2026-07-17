require "rails_helper"

RSpec.describe UserMailer, type: :mailer do
  describe "welcome_email" do
    # Create a safe mock user to feed into the mailer method
    let(:user) { User.create!(username: "test_welcomed", email: "welcome@test.com", password: "password123") }
    let(:mail) { UserMailer.welcome_email(user) } # ✅ Pass the user object here!

    it "renders the headers" do
      expect(mail.subject).to include("Welcome to Rennlad Academy")
      expect(mail.to).to eq([ user.email ])
      expect(mail.from).to eq([ "welcome@rennladacademy.com" ])
    end

    it "renders the body" do
      expect(mail.html_part.body.encoded).to include(user.username)
      expect(mail.html_part.body.encoded).to include("1200 Elo")
    end
  end
end
