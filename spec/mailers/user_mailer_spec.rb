# spec/mailers/user_mailer_spec.rb
# =========================================================================
# TRANSACTION COMMUNICATIONS MAIL UNIT SPEC
# - Stress-tests outbound mail payload compilation and routing rules
# - Asserts recipient, sender, and dynamic subject fields map cleanly
# - Verifies unencoded multi-part text variables render user identities
# =========================================================================
require "rails_helper"

RSpec.describe UserMailer, type: :mailer do
  # --- Setup Shared Test Matrix Variables ---
  let!(:student) { User.create!(username: "email_scholar", email: "scholar@rennlad.com", password: "password123", role: :student) }
  let!(:mail_object) { UserMailer.welcome_email(student) }

  # =========================================================================
  # 1. MAIL PAYLOAD HEADER VALIDATIONS TESTS
  # =========================================================================
  describe "#welcome_email" do
    it "successfully compiles the email payload header fields and assigns recipient addresses" do
      expect(mail_object.to).to include("scholar@rennlad.com")
      expect(mail_object.from).to include("welcome@rennladacademy.com")
      expect(mail_object.subject).to include("Welcome to Rennlad Academy, email_scholar!")
    end

    # =========================================================================
    # 2. EMAIL BODY TRANSLATION STRUCTURAL TEXT MATCHES TESTS
    # =========================================================================
    it "injects dynamic student identity username strings straight into the email text body" do
      # Evaluates the compiled body string payload (works for both multi-part HTML and text frames)
      expect(mail_object.html_part.body.decoded).to include("email_scholar")
    end
  end
end
