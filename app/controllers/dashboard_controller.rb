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

  # GET /admin/dashboard/submissions
  def submissions
    @pending_submissions = Submission.includes(:submitter, :prompt).where(status: :submitted).order(created_at: :asc)
    @corrected_submissions = Submission.includes(:submitter, :prompt, :corrector).where(status: :corrected).order(updated_at: :desc)
  end

  # GET /admin/dashboard/submissions/:id
  def show_submission
    @submission = Submission.find(params[:id])
  end

  # PATCH /admin/dashboard/submissions/:id
  def grade_submission
    @submission = Submission.find(params[:id])

    # Process structured scoring maps passing through your form fields
    assigned_scores = params[:scores].permit!.to_h # grammar, vocabulary, coherence, task_achievement, pronunciation, etc.

    # Calculate a simple average float score out of the category hashes passed
    valid_scores = assigned_scores.values.map(&:to_f).select { |v| v > 0 }
    calculated_average = (valid_scores.sum / valid_scores.size).round(2) rescue 0.0

    if @submission.update(
      scores: assigned_scores,
      final_result: calculated_average,
      teacher_feedback: params[:teacher_feedback],
      corrector: current_user,
      status: :corrected
    )
      # Trigger an automated alert straight to the student's notification center
      Notification.create!(
        recipient: @submission.submitter,
        actor: current_user,
        event_type: "system_alert",
        params: {
          "message" => "corrected your #{@submission.prompt.prompt_type} task: '#{@submission.prompt.title}'",
          "url" => "/submissions/#{@submission.id}"
        }
      )

      flash[:notice] = "Submission graded successfully. Student notified."
      redirect_to admin_submissions_path
    else
      flash[:alert] = "Grading update failed: #{@submission.errors.full_messages.join(', ')}"
      render :show_submission
    end
  end
end
