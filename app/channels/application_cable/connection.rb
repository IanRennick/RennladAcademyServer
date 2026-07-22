# app/channels/application_cable/connection.rb
# =========================================================================
# REAL-TIME SYSTEM COMMUNICATIONS GATEWAY CONNECTION LAYER
# - Establishes the core secure handshake authorization gate for WebSockets
# - Extracts active Devise session authentication identities using Warden hooks
# - Intercepts anonymous guest profiles early via immediate thread rejections
# =========================================================================
module ApplicationCable
  class Connection < ActionCable::Connection::Base
    # Instantiates a unique session tracking identifier for inheriting channels
    identified_by :current_user

    # Primary entry point executed upon outbound websocket handshake requests
    def connect
      self.current_user = find_verified_user
    end

    private

    # Validates active authentication parameters inside client cookie environments
    def find_verified_user
      # Direct integration with Warden environment variables maps active Devise accounts
      if (verified_user = env["warden"].user)
        verified_user
      else
        # Strict boundary guard locks anonymous socket requests completely out of server memory
        reject_unauthorized_connection
      end
    end
  end
end
