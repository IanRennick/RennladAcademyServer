module Api
  module V1
    module Users
      class RegistrationsController < ApiController
        # Skip logged in check when registering new user
        skip_before_action :doorkeeper_authorize!, only: %i[create]

        # Include concern
        include DoorkeeperRegisterable


        def create
          # Get Doorkeeper Application
          client_app = Doorkeeper::Application.find_by(uid: user_params[:client_id])

          # Send error if can't find Doorkeeper Application
          unless client_app
            render json: { error: I18n.t("doorkeeper.errors.messages.invalid_client") }, status: :unauthorized
          end

          # Create New User
          allowed_params = user_params.except(:client_id)
          user = User.new(allowed_params)

          if user.save
            # Return User Object from Doorkeeper Registerable Concern
            render json: render_user(user, client_app), status: :ok
          else
            # Return error if User not created
            render json: { errors: user.errors }, status: :unprocessable_entity
          end
        end


        private
        def user_params
          params.permit(:email, :password, :client_id)
        end
      end
    end
  end
end
