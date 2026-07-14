Rails.application.initialize!

if Rails.env.production?
  Thread.new do
    # Give the primary web server 5 seconds to bind its network ports first
    sleep 5
    puts "📡 [Initial Boot] Starting full production database initialization..."

    begin
      Rake::Task.clear
      Rails.application.load_tasks

      # 1. Compile layout assets to fix 404 styling warnings
      puts "📡 [Initial Boot] Compiling layout assets..."
      Rake::Task["assets:precompile"].invoke
      puts "📡 [Initial Boot] Asset compilation complete!"

      # 2. Run seeds first to build your CEFR Levels and Doorkeeper keys safely
      puts "📡 [Initial Boot] Committing database seed records..."
      Rails.application.load_seed
      puts "📡 [Initial Boot] Seeds completed successfully!"

      # 3. Run puzzle importer second now that Levels are fully guaranteed
      puts "📡 [Initial Boot] Invoking curriculum puzzle uploader task..."
      Rake::Task["db:import_puzzles"].invoke
      puts "📡 [Initial Boot] 250+ questions imported successfully into Postgres!"

    rescue => e
      puts "❌ [Initial Boot Error]: #{e.message}"
    end
  end
end
