class UsersController < ApplicationController
  before_action :set_user
  def profile
  end



  private

  # Method to set user when visiting User profile page
  def set_user
    @user = User.find(params[:id])
  end
end
