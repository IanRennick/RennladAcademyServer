class AdminController < ApplicationController
  def index
  end

  def users
  end

  def writings
    # Get all writings
    @writings = Writing.all.includes(:user)
  end

  def show_writing
    # Get writing from params
    @writing = Writing.find(params[:id])
  end
end
