# config/environment.rb
require_relative "application"

# ✅ FIX: Explicitly require the Rake module file so the background thread recognizes Rake::Task!
require "rake"

Rails.application.initialize!

if Rails.env.production?
  Thread.new do
    sleep 5
    Rails.application.executor.wrap do
      puts "📡 [Initial Boot] Invoking curriculum puzzle uploader task..."
      begin
        Rake::Task.clear
        Rails.application.load_tasks
        Rake::Task["db:import_puzzles"].invoke
        puts "📡 [Initial Boot] 250+ questions imported successfully into Postgres!"
      rescue => e
        puts "❌ [Initial Boot Error]: #{e.message}"
      end
    end
  end
end
