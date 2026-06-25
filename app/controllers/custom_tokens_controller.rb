class CustomTokensController < Doorkeeper::TokensController
  # Include cookie helpers since Doorkeeper's base controller lacks them
  include ActionController::Cookies

  def create
    # Let Doorkeeper process the request and build the initial response
    super

    # 2. Set the cookie using your existing logic
    set_refresh_token_cookie

    # 3. Modify the response body if the request was successful
    if response.status == 200
      begin
        # Parse the original JSON body
        body_json = JSON.parse(response.body)

        # Keep ONLY the access token, discarding expires_in, refresh_token, scope, etc.
        # Doorkeeper outputs string keys by default
        filtered_body = body_json.slice("access_token")

        # Overwrite the response body with the filtered JSON
        self.response_body = filtered_body.to_json
      rescue JSON::ParserError
        # Fallback safety in case response body isn't valid JSON
      end
    end
  end

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
