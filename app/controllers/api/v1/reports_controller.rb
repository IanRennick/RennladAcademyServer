# app/controllers/api/v1/reports_controller.rb
# =========================================================================
# STATELESS API V1 CROWDSOURCED TYPO & BUG REPORTING CONTROLLER
# - Inherits from ApiController to mandate secure OAuth bearer token parsing
# - Logs flexible front-end issue descriptions linked directly to database questions
# - Dispatches automated, real-time system alerts to all active administrators
# =========================================================================
module Api
  module V1
    class ReportsController < ApiController
      # --- Action Lifecycle Filters Matrix ---
      before_action :authenticate_api_user!

      # --- Action Endpoints ---

      # POST /api/v1/reports
      def create
        @report = current_user.reports.new(report_params)

        if @report.save
          # DISPATCH AUTOMATED WORKFLOW NOTIFICATION TO ALL ADMINS
          User.where(role: :admin).find_each do |admin|
            Notification.create!(
              recipient: admin,
              actor: current_user,
              event_type: "system_alert",
              params: {
                "message" => "submitted a fresh #{@report.report_type.humanize.downcase} ticket",
                "text_snippet" => @report.description.truncate(35),
                "url" => "/admin/dashboard" # Direct link to check tickets on your admin HTTP pane
              }
            )
          end

          render json: { message: "Report logged successfully", id: @report.id }, status: :created
        else
          render json: { errors: @report.errors.full_messages }, status: :unprocessable_content
        end
      end

      private

      # Strict parameter perimeter shield filtering incoming inputs
      def report_params
        params.require(:report).permit(:report_type, :description, :question_id, :url)
      end
    end
  end
end
