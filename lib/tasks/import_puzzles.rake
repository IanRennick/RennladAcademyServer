require "csv"

namespace :db do
  desc "Import puzzles from all CSV files inside the db directory"
  task import_puzzles: :environment do
    # Scans your db/ directory and grabs every file ending in .csv automatically
    csv_files = Dir[Rails.root.join("db", "*.csv")]

    if csv_files.empty?
      puts "❌ Error: No CSV files found inside the db/ directory!"
      next
    end

    puts "🚀 Starting puzzle import sequence across #{csv_files.count} file(s)..."
    import_count = 0
    skipped_count = 0

    csv_files.each do |file_path|
      puts "📁 Processing file: #{File.basename(file_path)}..."

      # headers: true tells Ruby to map columns by their header names, ignoring column positions
      CSV.foreach(file_path, headers: true) do |row|
        # 1. Look up the CEFR level record (e.g. "B2") safely
        level_name = row["level"]&.to_s&.strip&.upcase
        level_record = Level.find_by(name: level_name)

        if level_record.nil?
          puts "  ⚠️ Skipping row: Level '#{row['level']}' does not exist in your seeds!"
          skipped_count += 1
          next
        end

        # 2. Convert comma-separated string parameters into clean Ruby data arrays
        cleaned_options = row["options"].present? ? row["options"].split(",").map(&:strip) : []
        cleaned_answers = row["answers"].present? ? row["answers"].split(",").map(&:strip) : []

        # 3. Secure Sync Guard: Find an existing question by its text or initialize a new one
        question = Question.find_or_initialize_by(main: row["main"].to_s.strip)

        # 4. Assign all column properties dynamically from your spreadsheet headers
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

        # 5. Save to your database (triggers your automatic initial Elo callbacks automatically!)
        if question.save
          import_count += 1
        else
          puts "  ❌ Failed to save question: #{question.errors.full_messages.join(', ')}"
          skipped_count += 1
        end
      end
    end

    puts "========================================================="
    puts "🎉 Done! Successfully synchronized #{import_count} puzzles into the database."
    puts "⚠️ Skipped/Failed rows: #{skipped_count}" if skipped_count > 0
    puts "========================================================="
  end
end
