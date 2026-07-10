module DoorkeeperRegisterable
  extend ActiveSupport::Concern

  # Generate a new refresh token
  def generate_refresh_token
    loop do
      # Create a token
      token = SecureRandom.hex(32)
      # Check token doesn't match one already in use
      break token unless Doorkeeper::AccessToken.exists?(refresh_token: token)
    end
  end

  # Method to return a User Object after Registration with Secure Cookies
  def render_user(user, client_app)
    # 1. Create the native Doorkeeper Access Token
    access_token = Doorkeeper::AccessToken.create!(
      resource_owner_id: user.id,
      application_id: client_app.id,
      refresh_token: generate_refresh_token,
      expires_in: Doorkeeper.configuration.access_token_expires_in.to_i,
      scopes: ""
    )

    # 2. Write the refresh token securely into cookies (Matches CustomTokensController)
    cookies.encrypted[:_refresh_token] = {
      value: access_token.refresh_token,
      httponly: true,                         # Protects against XSS
      secure: Rails.env.production?,          # Only HTTPS in production
      same_site: :lax,                        # Protects against CSRF
      expires: 14.days.from_now,
      path: "/"                               # Global path matching logout
    }

    # 3. Format of the Response Body (Keep ONLY the access token)
    {
      access_token: access_token.token
    }
  end
end
