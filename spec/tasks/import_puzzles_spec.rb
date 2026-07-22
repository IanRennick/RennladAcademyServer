# spec/tasks/import_puzzles_spec.rb
# =========================================================================
# RAKE INGESTION INVENTORY PROVISIONING TASK SPEC
# - Verifies file parsing skips gracefully if directory streams return empty
# - Safeguards the database layer against incomplete multi-row corruptions
# =========================================================================
require "rails_helper"
require "rake"

RSpec.describe "db:import_puzzles Rake Task Ingestion", type: :task do
  before :all do
    Rails.application.load_tasks
  end

  after :each do
    Rake.application.tasks.each(&:reenable)
  end

  # --- Setup Shared Test Matrix Variables ---
  let!(:b2_level) { Level.find_or_create_by!(name: "B2") { |l| l.initial_rating = 1200 } }

  # =========================================================================
  # 1. EXCEPTION BOUNDARIES LOG OUTPUTS TEST
  # =========================================================================
  it "skips the transaction sequence safely and outputs an error if the db directory contains no files" do
    allow(Dir).to receive(:[]).and_return([])

    expect {
      expect { Rake::Task["db:import_puzzles"].invoke }.to output(/No CSV files found/).to_stdout
    }.not_to change(Question, :count)
  end
end
