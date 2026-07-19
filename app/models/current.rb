# app/models/current.rb
# =========================================================================
# THREAD-SAFE ISOLATED REQUEST RUNTIME PROFILE CONTAINER
# - Inherits from ActiveSupport::CurrentAttributes to manage global variables
# - Automatically tracks parameters across a single controller request execution loop
# - Clears variables dynamically at the end of each web stream loop to prevent memory leaks
# =========================================================================
class Current < ActiveSupport::CurrentAttributes
  # Enforces thread-isolated memory allocation for the incoming ActionDispatch web context request object
  attribute :request

  # --- Operational Lifecycle Sync ---
  # ActiveSupport automatically flushes these attributes for you on request teardown,
  # but declaring structural context tracking here ensures safety for your frontend sprint.
end
