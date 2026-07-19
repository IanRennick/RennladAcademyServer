# app/controllers/messages_controller.rb
# =========================================================================
# REAL-TIME COMMUNICATIONS SUITE INGESTION CONTROLLER
# - Handles inbound real-time text message submissions from chat rooms
# - Integrates Rails 8 strict parameter filtering boundaries
# - Leverages model validations to handle participant authorization rules
# =========================================================================
class MessagesController < ApplicationController
  # --- Action Endpoints ---

  # POST /rooms/:room_id/messages
  def create
    # Instantiate the message record scoped tightly to the active user session context
    @message = current_user.messages.new(
      body: message_params[:body],
      room_id: params[:room_id]
    )

    # Core validation rules inside the model handle security and broadcast lifecycles
    unless @message.save
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.append("messages", partial: "messages/error", locals: { message: @message }) }
        format.html { redirect_back(fallback_location: root_path, alert: "Unable to deliver chat message packet payload.") }
      end
    end
  end

  private

  # Enforces modern Rails 8 parameters whitelisting rules to block malicious form payloads
  def message_params
    params.expect(message: [ :body ])
  end
end
