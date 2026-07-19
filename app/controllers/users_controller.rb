# app/controllers/users_controller.rb
# =========================================================================
# STUDENT PROFILE PROFILE METRICS & DIRECT COMMUNICATIONS CONTROLLER
# - Generates multi-dimensional SQL joins to track CEFR proficiency brackets
# - Handles deterministic token matching arrays to route secure private direct messages
# =========================================================================
class UsersController < ApplicationController
  # --- Action Lifecycle Filters ---
  before_action :set_student_target_profile

  # --- Action Endpoints ---

  # GET /users/:id/profile
  def profile
    # Fetch performance tracking queues to populate dashboard feeds
    @review_queue    = @user.user_histories.where(needs_review: true).order(updated_at: :desc)
    @recent_activity = @user.user_histories.order(created_at: :desc).limit(15)
    @kind_stats      = @user.user_stats.where(stat_type: "kind")

    # Fetch recent asynchronous student forum comments
    @recent_comments = @user.comments.order(created_at: :desc).limit(5)

    # CEFR PERFORMANCE PIPELINE: Group history counts cleanly by level name tokens via explicit inner table joins
    history_by_level  = @user.user_histories.joins(:question).joins("JOIN levels ON questions.level_id = levels.id").group("levels.name")
    @total_by_level   = history_by_level.count
    @correct_by_level = history_by_level.where(first_attempt_correct: true).count
  end

  # GET /users/:id/chat
  def chat
    @room    = Room.new
    @message = Message.new
    @rooms   = Room.public_rooms

    # Streamlined sidebar directory alignment orders active profiles to the top ceiling
    @users = User.all_except(current_user).order(status: :desc, username: :asc)

    # Deterministically calculate the unique private token signature between both entities
    @room_name = generate_deterministic_dm_token(@user, current_user)

    # ✅ PERFORMANCE FIXED: Replaced loose where lookups with an atomic find_by block to prevent thread race conditions
    @single_room = Room.find_by(name: @room_name) || Room.create_private_room([ @user, current_user ], @room_name)
    @messages    = @single_room.messages.includes(:user).order(created_at: :asc)

    render "rooms/index"
  end

  private

  # Scoped record extraction guard sets target user variables
  def set_student_target_profile
    @user = User.find(params[:id])
  end

  # Calculates a unique, sorted string hash matching pattern using primary key IDs
  def generate_deterministic_dm_token(user1, user2)
    sorted_nodes = [ user1, user2 ].sort_by(&:id)
    "private_#{sorted_nodes.first.id}_#{sorted_nodes.last.id}"
  end
end
