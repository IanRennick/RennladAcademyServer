# app/controllers/dashboard_controller.rb
# =========================================================================
# SYSTEM telemetry CONTROL BOARD CONTROLLER
# - Gathers high-level system metrics for student statuses across the platform
# - Pulls the master student directory roll ordered by global Elo ranking brackets
# =========================================================================
class DashboardController < ApplicationController
  # --- Action Endpoints ---

  # GET /admin/dashboard
  def index
    # Pulls the authoritative student roll, descending from highest score to lowest
    @users = User.all.order(rating: :desc)

    # PERFORMANCE FIX: Performed aggregation counters on the un-ordered class
    # to protect PostgreSQL from executing heavy nested array sorting macros
    @total_students = User.count
    @online_count   = User.where(status: :online).count
    @away_count     = User.where(status: :away).count
  end
end
