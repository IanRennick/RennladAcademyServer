class CustomTokensController < Doorkeeper::TokensController
  # Include cookie helpers since Doorkeeper's base controller lacks them
  include ActionController::Cookies
  after_action :set_refresh_token_cookie, only: [ :create ]


  # Add a dedicated logout method
  def revoke
    # 1. Let Doorkeeper handle revoking the token in the database natively
    super

    # 2. Clear the refresh token cookie from the client's browser
    cookies.delete(:_refresh_token)
  end


  private

  # Extract token from Doorkeeper result and place it safely into a cookie
  def set_refresh_token_cookie
    # 1. Ensure the authorization response was successful
    return unless authorize_response.is_a?(Doorkeeper::OAuth::TokenResponse)

    # 2. Extract the fresh token object from the response
    token_object = authorize_response.token
    return unless token_object&.refresh_token.present?

    # 3. Securely write the refresh token to cookies
    cookies.encrypted[:_refresh_token] = {
      value: token_object.refresh_token,
      httponly: true,                         # Protects against XSS
      secure: Rails.env.production?,          # Only HTTPS in production
      same_site: :lax,                        # Protects against CSRF
      expires: 14.days.from_now
    }
  end
end
