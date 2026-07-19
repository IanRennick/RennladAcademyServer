# app/controllers/api_controller.rb
# =========================================================================
# AUTHORITATIVE STATELESS API BASE CONTROLLER
# - Serves as the master parent class for all versioned JSON API endpoints
# - Bypasses standard browser cookie authenticity checks for stateless requests
# - Decouples and extracts current user entities using Doorkeeper OAuth Bearer tokens
# =========================================================================
class ApiController < ApplicationController
  # --- Action Filter Overrides ---
  # Bypasses standard web layout filters to allow fluid, stateless API execution
  skip_before_action :ensure_admin_access, raise: false
  skip_before_action :authenticate_user!, raise: false
  skip_before_action :verify_authenticity_token, raise: false

  # Enforce strict JSON responses globally across all inheriting sub-classes
  respond_to :json

  # --- Shared API Helper Methods ---

  # Dynamic lookup extracting the active token owner entity from the request thread
  def current_user
    return @current_user if defined?(@current_user)

    # Doorkeeper injects the authenticated doorkeeper_token object automatically
    if respond_to?(:doorkeeper_token) && doorkeeper_token&.accessible?
      @current_user = User.find_by(id: doorkeeper_token.resource_owner_id)
    else
      @current_user = nil
    end
  end

  # Reusable filter endpoint ensuring sub-actions block unauthenticated clients
  def authenticate_api_user!
    if current_user.nil?
      render json: { error: "Valid OAuth Bearer token authentication required." }, status: :unauthorized
    end
  end
end
