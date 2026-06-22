module CustomTokenResponse
  def body
    # Get the original response payload
    original_body = super

    # Extract the refresh token if present
    if original_body[:refresh_token].present?
      # Pass the token string up to the controller layer via thread or custom hook
      # Or directly manage cookies if accessible, but standard practice is
      # returning the body without the token to be processed by a middleware or custom controller.
      @refresh_token_value = original_body.delete(:refresh_token)
    end

    original_body
  end
end
