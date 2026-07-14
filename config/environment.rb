# Load the Rails application.
require_relative "application"

# Initialize the Rails application.
Rails.application.initialize!

# 🚀 TEMPORARY V1 PRODUCTION INITIALIZER TRICK
# This executes automatically inside Render's free container exactly once during boot!
if Rails.env.production?
  Thread.new do
    # Give the primary web server 5 seconds to bind its ports cleanly first
    sleep 5
    puts "📡 [Boot Trigger] Starting database seeding process..."

    begin
      # 1. Run seeds first to guarantee levels and Doorkeeper client exist
      Rails.application.load_seed
      puts "📡 [Boot Trigger] Seeds completed successfully!"

      # 2. Programmatically invoke your spreadsheet puzzle uploader rake task
      puts "📡 [Boot Trigger] Invoking spreadsheet uploader..."
      Rake::Task.clear # Reset rake memory tracking maps
      Rails.application.load_tasks
      Rake::Task["db:import_puzzles"].invoke
      puts "📡 [Boot Trigger] 250+ questions imported successfully into Postgres!"

    rescue => e
      puts "❌ [Boot Trigger Error]: #{e.message}"
    end
  end
end
