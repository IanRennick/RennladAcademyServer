# app/mailers/user_mailer.rb
# =========================================================================
# SYSTEM TRANSACTUAL COMMUNICATIONS MAIL CONTROLLER
# - Provisions core outbound transaction notification delivery blocks
# - Automatically resolves recipient targets and compiles branding headers
# =========================================================================
class UserMailer < ApplicationMailer
  # Static system-supported fallback sender string parameters configuration
  default from: "welcome@rennladacademy.com"

  # --- Outbound Mail Delivery Actions ---

  def welcome_email(user)
    @user = user

    # Dynamic configuration parameter lookup with hardcoded safety string fallback boundaries
    sender_address = Rails.configuration.x.mailer.default_from rescue "welcome@rennladacademy.com"
    sender_address = "welcome@rennladacademy.com" if sender_address.blank?

    mail(
      from: sender_address,
      to: @user.email,
      subject: "Welcome to Rennlad Academy, #{@user.username}! 🚀"
    )
  end
end
