class AdminController < ApplicationController
  def index
  end

  def users
  end

  def writings
    @writings = Writing.all.includes(:user, :comments)
  end

  def show_writing
    @writing = Writing.includes(:user, :comments).find(params[:id])
  end
end
