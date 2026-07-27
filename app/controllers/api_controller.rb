# app/controllers/api_controller.rb
# =========================================================================
# AUTHORITATIVE STATELESS API BASE CONTROLLER
# - Serves as the master parent class for all versioned JSON API endpoints
# - Bypasses standard browser cookie authenticity checks for stateless requests
# - Decouples and extracts current user entities using Doorkeeper OAuth Bearer tokens
# =========================================================================
class ApiController < ApplicationController
  # Force Doorkeeper header extraction streams across all versioned endpoints
  before_action :doorkeeper_authorize!

  # Bypasses standard web layout filters to allow fluid, stateless API execution
  skip_before_action :ensure_admin_access, raise: false
  skip_before_action :authenticate_user!, raise: false
  skip_before_action :verify_authenticity_token, raise: false

  # Enforce strict JSON responses globally across all inheriting sub-classes
  respond_to :json

  # --- Shared API Helper Methods ---

  # Dynamic lookup extracting the active token owner entity from the request thread
  def current_user
    # Return the cached user instantly if it has already been populated in this request thread
    return @current_user if @current_user.present?

    # Securely extract the token payload using Doorkeeper's primitive method.
    # We trap exceptions safely to prevent unexpected token loading crashes.
    token = begin
      doorkeeper_token
    rescue NameError, NoMethodError
      nil
    end

    if token.present?
      # Resolve the user's integer identity ID out of the raw token attributes data envelope
      user_id = token.respond_to?(:resource_owner_id) ? token.resource_owner_id : token[:resource_owner_id]
      @current_user = User.find_by(id: user_id)
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
