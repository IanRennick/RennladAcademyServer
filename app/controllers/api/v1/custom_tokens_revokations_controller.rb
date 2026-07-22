# app/controllers/custom_token_revocations_controller.rb
# =========================================================================
# OAUTH REVOCATION COOKIE-PURGE CONTROLLER
# - Overrides Doorkeeper::TokenRevocationsController to handle token logout bounds
# - Clears encrypted browser session refresh token tracking cookies dynamically
# =========================================================================
module Api
  module V1
    class CustomTokenRevocationsController < Doorkeeper::TokensController
      include ActionController::Cookies

      # Bypasses standard ApplicationController security walls safely
      skip_before_action :authenticate_user!, raise: false
      skip_before_action :ensure_admin_access, raise: false
      skip_before_action :sync_user_presence_and_activity, raise: false

      # --- Action Endpoints ---

      # POST /api/v1/oauth/revoke
      def create
        # Let Doorkeeper natively locate and revoke the target record string inside the database
        super

        # Purge the HTTP-Only browser cookie to clear the client identity completely
        cookies.delete(:_refresh_token, path: "/")
      end
    end
  end
end
