# lib/tasks/import_puzzles.rake
# =========================================================================
# SYSTEM DATA PROVISIONING & WORKSPACE SEEDING TASK
# - Streams and parses multi-column CSV question spreadsheets safely
# - Resolves CEFR difficulty dependencies on the fly via table associations
# - Runs within an atomic transaction block to protect database integrity
# =========================================================================
require "csv"

namespace :db do
  desc "Import puzzles from all CSV files inside the db directory securely"
  task import_puzzles: :environment do
    csv_files = Dir[Rails.root.join("db", "*.csv")]

    if csv_files.empty?
      puts "❌ Error: No CSV files found inside the db/ directory!"
      next
    end

    puts "🚀 Starting puzzle import sequence across #{csv_files.count} file(s)..."
    import_count = 0
    skipped_count = 0

    # TRANSACTION WRAPPER: Protects multi-row writes from database fragmentation crashes
    ActiveRecord::Base.transaction do
      csv_files.each do |file_path|
        puts "📁 Processing file: #{File.basename(file_path)}..."

        CSV.foreach(file_path, headers: true) do |row|
          # 1. Resolve CEFR association targets safely
          level_name = row["level"]&.to_s&.strip&.upcase
          level_record = Level.find_by(name: level_name)

          if level_record.nil?
            puts "  ⚠️ Skipping row: Level '#{row['level']}' does not exist inside your registry seeds!"
            skipped_count += 1
            next
          end

          # 2. Clean array string parameters safely
          cleaned_options = row["options"].present? ? row["options"].split(",").map(&:strip) : []
          cleaned_answers = row["answers"].present? ? row["answers"].split(",").map(&:strip) : []

          # 3. Idempotent search guard prevents duplication logs
          question = Question.find_or_initialize_by(main: row["main"].to_s.strip)

          question.assign_attributes(
            kind: row["kind"].to_s.strip,
            subtype: row["subtype"].presence,
            level: level_record,
            options: cleaned_options,
            answers: cleaned_answers,
            tag_list: row["tag_list"].presence,
            keyword: row["keyword"].presence,
            prompt: row["prompt"].presence
          )

          if question.save
            import_count += 1
          else
            puts "  ❌ Failed to save question: #{question.errors.full_messages.join(', ')}"
            skipped_count += 1
          end
        end
      end
    end

    puts "========================================================="
    puts "🎉 Done! Successfully synchronized #{import_count} puzzles into the database."
    puts "⚠️ Skipped/Failed rows: #{skipped_count}" if skipped_count > 0
    puts "========================================================="
  end
end
