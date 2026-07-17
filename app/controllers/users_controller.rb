class UsersController < ApplicationController
  before_action :set_user
  def profile
    @review_queue = @user.user_histories.where(needs_review: true).order(updated_at: :desc)
    @recent_activity = @user.user_histories.order(created_at: :desc).limit(15)
    @kind_stats = @user.user_stats.where(stat_type: "kind")

    # 1. NEW: Fetch the student's 5 most recent comments across all puzzles
    @recent_comments = @user.comments.order(created_at: :desc).limit(5)

    # 2. NEW: Calculate CEFR Level Accuracy metrics dynamically on the fly
    # We group history logs by the associated question's level name string
    history_by_level = @user.user_histories.joins(:question).joins("JOIN levels ON questions.level_id = levels.id").group("levels.name")

    @total_by_level = history_by_level.count # e.g., {"B2" => 10, "C1" => 5}
    @correct_by_level = history_by_level.where(first_attempt_correct: true).count # e.g., {"B2" => 8, "C1" => 2}
  end

  def chat
    # Get list of all other users
    @users = User.all_except(current_user)

    @room = Room.new
    @message = Message.new

    @rooms = Room.public_rooms

    @room_name = get_name(@user, current_user)

    @single_room = Room.where(name: @room_name).first || Room.create_private_room([ @user, current_user ], @room_name)

    @messages = @single_room.messages.includes([ :user ]).order(created_at: :asc)

    render "rooms/index"
  end

  private
  # Method to set user when visiting User profile page
  def set_user
    @user = User.find(params[:id])
  end

  def get_name(user1, user2)
    user = [ user1, user2 ].sort
    "private_#{user[0].id}_#{user[1].id}"
  end
end
