# app/controllers/custom_tokens_controller.rb
# =========================================================================
# ADVANCED OAUTH COOKIE-ISOLATION TOKEN CONTROLLER
# - Overrides Doorkeeper::TokensController to decouple access and refresh tokens
# - Strips refresh tokens out of raw JSON bodies to protect front-end assets
# =========================================================================
class CustomTokensController < Doorkeeper::TokensController
  include ActionController::Cookies

  skip_before_action :authenticate_user!, raise: false
  skip_before_action :ensure_admin_access, raise: false
  skip_before_action :sync_user_presence_and_activity, raise: false

  # --- Action Endpoints ---

  # POST /api/v1/oauth/token
  def create
    super
    set_refresh_token_cookie

    if response.successful?
      begin
        body_json = JSON.parse(response.body)
        filtered_body = body_json.slice("access_token")
        self.response_body = filtered_body.to_json
      rescue JSON::ParserError => e
        Rails.logger.error "OAUTH JSON Parse Exception: #{e.message}"
      end
    end
  end

  private

  # Extract token metrics from Doorkeeper result parameters to build cookies
  def set_refresh_token_cookie
    return unless authorize_response.is_a?(Doorkeeper::OAuth::TokenResponse)

    token_object = authorize_response.token
    return unless token_object&.refresh_token.present?

    cookies.encrypted[:_refresh_token] = {
      value: token_object.refresh_token,
      httponly: true,
      secure: Rails.env.production?,
      same_site: :lax,
      expires: 14.days.from_now
    }
  end
end
