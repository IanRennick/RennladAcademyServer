# app/controllers/api/v1/users/registrations_controller.rb
# =========================================================================
# STATELESS API V1 STUDENT ENROLLMENT GATEWAY CONTROLLER
# - Handles high-speed stateless registrations for remote clients
# - Validates incoming client application keys against Doorkeeper registries
# =========================================================================
module Api
  module V1
    module Users
      class RegistrationsController < ApiController
        # Skip token authorization rules on user registration creation endpoints
        skip_before_action :authenticate_api_user!, raise: false

        # Include cross-cutting OAuth token generation cookie utilities
        include DoorkeeperRegisterable

        # POST /api/v1/users
        def create
          # Verify the requesting front-end application matches a valid registry entity
          client_app = Doorkeeper::Application.find_by(uid: registration_params[:client_id])

          unless client_app
            return render json: { error: I18n.t("doorkeeper.errors.messages.invalid_client") }, status: :unauthorized
          end

          # Strip out client identifiers to isolate clean user construction parameters
          clean_user_params = registration_params.except(:client_id)
          user = User.new(clean_user_params)

          if user.save
            # Generates access tokens and appends secure HTTP-Only cookies automatically
            render json: render_user(user, client_app), status: :ok
          else
            # Upgraded to clean string arrays and shifted to modern Rack 3.0 statuses
            render json: { errors: user.errors.full_messages }, status: :unprocessable_content
          end
        end

        private

        # Enforces a clean parameter perimeter shield
        def registration_params
          params.permit(:email, :username, :password, :client_id)
        end
      end
    end
  end
end
