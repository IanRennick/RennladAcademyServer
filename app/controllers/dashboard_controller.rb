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

  # GET /admin/dashboard/reports
  def reports
    # Collects crowd-sourced bug issues, eager loading associations to prevent N+1 query leaks
    @reports = Report.includes(:user, :question).order(created_at: :desc)
  end

  # PATCH /admin/dashboard/reports/:id
  def resolve_report
    @report = Report.find(params[:id])

    # Toggles active ticket status state loops efficiently
    if @report.open? || @report.investigating?
      @report.resolved!
      flash[:notice] = "Ticket ##{@report.id} marked as resolved successfully."
    else
      @report.open!
      flash[:notice] = "Ticket ##{@report.id} re-opened for active investigation."
    end

    redirect_to admin_reports_path
  end
end
