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

  # Method to return a User Object after Registration
  def render_user(user, client_app, token_type = "Bearer")
    access_token = Doorkeeper::AccessToken.create(
      resource_owner_id: user.id,
      application_id: client_app.id,
      refresh_token: generate_refresh_token,
      expires_in: Doorkeeper.configuration.access_token_expires_in.to_i,
      scopes: ""
    )

    # Format of User Object
    {
      id: user.id,
      access_token: access_token.token,
      token_type: token_type,
      expires_in: access_token.expires_in,
      refresh_token: access_token.refresh_token,
      created_at: access_token.created_at.to_time.to_i
    }
  end
end
