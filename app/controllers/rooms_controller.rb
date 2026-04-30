class RoomsController < ApplicationController
  def index
    @room = Room.new

    # Get all public rooms
    @rooms = Room.public_rooms

    # Get all other users
    @users = User.all_except(current_user)

    render "index"
  end

  def create
    @room = Room.create(room_params)
  end

  def show
    # Get open room
    @single_room = Room.find(params[:id])

    @room = Room.new
    @message = Message.new

    # Get all public rooms
    @rooms = Room.public_rooms

    # Get all essages and order by created at
    @messages = @single_room.messages.order(created_at: :asc)

    # Get all other users
    @users = User.all_except(current_user)

    render "index"
  end



  private
    # Only allow a list of trusted parameters through.
    def room_params
      params.expect(room: [ :name ])
    end
end
