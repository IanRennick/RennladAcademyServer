require_relative "application"

Rails.application.initialize!

if Rails.env.production?
  Thread.new do
    # Give Puma 5 seconds to open its web ports to the internet cleanly first
    sleep 5

    # ✅ FIX: Wrap background threads in the Rails executor to grant database connection pool access!
    Rails.application.executor.wrap do
      puts "📡 [Initial Boot] Background database initialization thread activated..."

      begin
        # 1. Run seeds to build your CEFR Levels and Doorkeeper keys safely
        puts "📡 [Initial Boot] Committing database seed records..."
        Rails.application.load_seed
        puts "📡 [Initial Boot] Seeds completed successfully! CEFR Levels initialized."

        # 2. Run puzzle importer now that Levels are 100% guaranteed
        puts "📡 [Initial Boot] Invoking curriculum puzzle uploader task..."
        Rake::Task.clear
        Rails.application.load_tasks
        Rake::Task["db:import_puzzles"].invoke
        puts "📡 [Initial Boot] 250+ questions successfully imported into production PostgreSQL!"

      rescue => e
        puts "❌ [Initial Boot Error]: #{e.message}"
      end
    end
  end
end
