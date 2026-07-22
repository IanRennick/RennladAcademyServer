# spec/tasks/import_puzzles_spec.rb
require "rails_helper"
require "rake"

RSpec.describe "db:import_puzzles Rake Task Ingestion", type: :task do
  before :all do
    # Load your application's Rake tasks into memory context once for this file
    Rails.application.load_tasks
  end

  # Re-enable the task after each run so it can be called cleanly across multiple contexts
  after :each do
    Rake.application.tasks.each(&:reenable)
  end

  # --- Setup Shared Test Matrix Variables ---
  let!(:b2_level) { Level.find_or_create_by!(name: "B2") { |l| l.initial_rating = 1200 } }

  it "skips the transaction sequence safely and outputs an error if the db directory contains no files" do
    allow(Dir).to receive(:[]).and_return([]) # Simulate an empty folder state

    expect {
      expect { Rake::Task["db:import_puzzles"].invoke }.to output(/No CSV files found/).to_stdout
    }.not_to change(Question, :count)
  end
end
