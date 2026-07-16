class PagesController < ApplicationController

  def home
  end

  def info
    # Get info about Doorkeeper Application
    @application = Doorkeeper::Application.where(name: "Web Client").first

    @application = {
      name: @application.name,
      client_id: @application.uid,
      client_secret: @application.secret
    }
  end
end
