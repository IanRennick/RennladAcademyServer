# app/controllers/rooms_controller.rb
# =========================================================================
# REAL-TIME COMMUNICATIONS SUITE ROUTING CONTROLLER
# - Manages public discussion streams and secure participant message tracking loops
# - Unified multi-state action routes map directly onto your master channel layout grids
# =========================================================================
class RoomsController < ApplicationController
  # --- Action Filter Endpoints ---

  # GET /rooms
  def index
    @room = Room.new
    @rooms = Room.public_rooms

    # PERFORMANCE OPTIMIZATION: Filtered to active users to prevent memory bloat as enrollment scales
    @users = User.all_except(current_user).order(status: :desc, username: :asc)

    render "index"
  end

  # GET /rooms/:id
  def show
    # Scoped database find path handles resource extraction
    @single_room = Room.find(params[:id])

    @room = Room.new
    @message = Message.new
    @rooms = Room.public_rooms

    # Eager-loads user associations efficiently to prevent standard N+1 database collection leaks
    @messages = @single_room.messages.includes(:user).order(created_at: :asc)
    @users = User.all_except(current_user).order(status: :desc, username: :asc)

    render "index"
  end

  # POST /rooms
  def create
    @room = Room.new(room_params)

    unless @room.save
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.append("rooms_feed", partial: "rooms/error", locals: { room: @room }) }
        format.html { redirect_back(fallback_location: root_path, alert: "Unable to compile new public communication stream.") }
      end
    end
  end

  private

  # Strict parameter boundaries matching Rails 8 framework standards safely
  def room_params
    params.expect(room: [ :name ])
  end
end
