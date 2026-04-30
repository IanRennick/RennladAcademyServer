class MessagesController < ApplicationController
  def create
    # Create new message
    @message = current_user.messages.create(body: message_params[:body], room_id: params[:room_id])
  end


  private
    # Only allow a list of trusted parameters through.
    def message_params
      params.expect(message: [ :body ])
    end
end
