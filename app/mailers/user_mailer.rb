# app/mailers/user_mailer.rb
class UserMailer < ApplicationMailer
  # Change the default sender string to match your platform brand
  default from: "welcome@rennladacademy.com"

  def welcome_email(user)
    @user = user
    # This queries your mail views and handles the secure multi-part transport formatting
    mail(to: @user.email, subject: "Welcome to Rennlad Academy, #{@user.username}! 🚀")
  end
end
