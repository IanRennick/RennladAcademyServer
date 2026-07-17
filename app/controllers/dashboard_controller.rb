class DashboardController < ActionController::Base
  def index
    # Pulls all users, ordered by highest Elo rating down to lowest
    @users = User.all.order(rating: :desc)

    # Calculate global station statistics
    @total_students = @users.count
    @online_count = @users.where(status: :online).count
    @away_count = @users.where(status: :away).count
  end
end
