class ApiController < ApplicationController
  # Ensure User is Logged in
  skip_before_action :ensure_admin_access

  # Skip checking CSFR token authenticity for API requests
  skip_before_action :verify_authenticity_token

  # Only respond with JSON
  respond_to :json

  # Set the Current User
  def current_user
    @current_user ||= User.find_by(id: doorkeeper_token[:resource_owner_id])
  end
end
