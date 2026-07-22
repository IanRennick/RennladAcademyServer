# config/application.rb
# =========================================================================
# AUTHORITATIVE PLATFORM SYSTEM CONFIGURATION APPLICATION HUB
# - Configures base frame dependencies, global middleware stacks, and engines
# - Sets up automated server-reset fallback callbacks to flush statuses
# - Enforces clean automated loading perimeters to protect production paths
# =========================================================================
require_relative "boot"
require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Server
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Reset online statuses when server is reset
    # FIXED: Waits for full boot initialization before running database modifications!
    config.after_initialize do
      if ActiveRecord::Base.connection_pool.active_connection? || ActiveRecord::Base.connection
        if ActiveRecord::Base.connection.table_exists?("users")
          User.update_all(status: :offline)
        end
      end
    rescue => e
      # Silently prevent migrations, asset compiling, and security scans from failing
      Rails.logger.warn "Skipped offline user sync during early boot initialization task: #{e.message}"
    end

    # Force load the custom context middleware using an absolute Rails root hook
    # to prevent early-boot require relative namespace pointer collisions!
    require Rails.root.join("lib", "request_store_middleware")
    config.middleware.use RequestStoreMiddleware

    # Explicitly ignore your manually required middleware file inside the library
    # exclusion tracker array to successfully bypass FrozenArray crashes during CI runs!
    config.autoload_lib(ignore: %w[assets tasks request_store_middleware])

    # Configuration for the application, engines, and railties goes here.
    # Settings can be overridden in specific environments using the files in config/environments.
  end
end
