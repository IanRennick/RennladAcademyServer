require_relative "boot"
require_relative "../lib/request_store_middleware"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Server
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Reset online statuses when server is reset
    config.after_initialize do |_config|
      User.update_all(status: User.statuses[:offline])
    end

    # Execute this early in the stack to track the context safely
    config.middleware.use RequestStoreMiddleware

    # Remove or comment out this entire block:
    # config.after_initialize do |_config|
    #   if ActiveRecord::Base.connection.table_exists?(:users)
    #     User.update_all(status: User.statuses[:offline])
    #   end
    # end

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
