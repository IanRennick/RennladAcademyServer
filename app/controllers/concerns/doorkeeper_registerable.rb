# app/controllers/concerns/doorkeeper_registerable.rb
# =========================================================================
# OAUTH ACCOUNT REGISTRATION STATELESS UTILITY CONCERN
# - Programmatically handles low-level secure token loop generations
# - Inject encrypted HttpOnly browser refresh cookies to shield tokens from XSS/CSRF
# =========================================================================
module DoorkeeperRegisterable
  extend ActiveSupport::Concern

  # Generates a unique secure random token string that avoids collisions
  def generate_refresh_token
    loop do
      token = SecureRandom.hex(32)
      break token unless Doorkeeper::AccessToken.exists?(refresh_token: token)
    end
  end

  # Orchestrates token allocation and formatting layout outputs
  def render_user(user, client_app)
    # 1. Instantiate the authoritative Doorkeeper Access Token tuple
    access_token = Doorkeeper::AccessToken.create!(
      resource_owner_id: user.id,
      application_id: client_app.id,
      refresh_token: generate_refresh_token,
      expires_in: Doorkeeper.configuration.access_token_expires_in.to_i,
      scopes: ""
    )

    # 2. Write the refresh token securely into browser cookie frames
    cookies.encrypted[:_refresh_token] = {
      value: access_token.refresh_token,
      httponly: true,                         # Blocks script injection reads
      secure: Rails.env.production?,          # Forces HTTPS in production channels
      same_site: :lax,                        # Neutralizes CSRF cross-origin loops
      expires: 14.days.from_now,
      path: "/"                               # Global channel path alignment
    }

    # 3. RESPONSE SECURITY MASK: Keep ONLY the access token in the JSON body
    {
      access_token: access_token.token
    }
  end
end
