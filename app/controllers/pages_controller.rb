class PagesController < ApplicationController
  def home
  end

  def info
    # Get info about Doorkeeper Application
    @application = Doorkeeper::Application.first

    @application = {
      client_id: @application.uid,
      client_secret: @application.secret
    }
  end
end
