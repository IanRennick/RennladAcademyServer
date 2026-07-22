# spec/mailers/user_mailer_spec.rb
require "rails_helper"

RSpec.describe UserMailer, type: :mailer do
  describe "#welcome_email" do
    # --- Setup Shared Test Matrix Variables ---
    let!(:student) { User.create!(username: "email_scholar", email: "scholar@rennlad.com", password: "password123", role: :student) }
    let!(:mail_object) { UserMailer.welcome_email(student) }

    it "successfully compiles the email payload header fields and assigns recipient addresses" do
      expect(mail_object.to).to include("scholar@rennlad.com")
      expect(mail_object.from).to include("welcome@rennladacademy.com")
      expect(mail_object.subject).to include("Welcome to Rennlad Academy, email_scholar!")
    end

    it "injects dynamic student identity username strings straight into the email text body" do
      # Evaluates the compiled body string payload (works for both multi-part HTML and text frames)
      expect(mail_object.html_part.body.decoded).to include("email_scholar")
    end
  end
end
