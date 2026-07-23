# spec/models/prompt_spec.rb
# =========================================================================
# UNIFIED EXAMINATION PROMPT MODEL MATRIX SPEC
# - Stress-tests JSONB parameter mapping arrays for writing assignments
# - Asserts required configuration keys enforce structural integrity rules
# =========================================================================
require "rails_helper"

RSpec.describe "Unified Examination Prompt System", type: :model do
  # --- Setup Shared Test Matrix Variables ---
  let!(:b2_level) { Level.find_or_create_by!(name: "B2") { |l| l.initial_rating = 1200 } }

  # =========================================================================
  # 1. WRITING PROMPT SCHEMA DATA COMPILING TESTS
  # =========================================================================
  describe "Writing Prompt Validations" do
    it "allows a valid writing task with flexible paragraphs to save cleanly" do
      prompt = Prompt.new(
        level: b2_level,
        prompt_type: "writing",
        title: "Technology in Classrooms",
        topic: "education",
        metadata: {
          "situation" => "Your teacher has asked you to write an essay...",
          "assignment_type" => "essay",
          "word_count" => "140-190",
          "bullet_points" => [ "Cost", "Distraction", "Student engagement" ],
          "instructions" => [ "Write your essay response.", "Give reasons for your choices." ]
        }
      )

      expect(prompt).to be_valid
      expect(prompt.bullet_points.count).to eq(3)
      expect(prompt.instructions.last).to eq("Give reasons for your choices.")
    end

    it "blocks writing prompts that omit mandatory task situations" do
      bad_prompt = Prompt.new(level: b2_level, prompt_type: "writing", title: "Broken Prompt", topic: "general", metadata: {})
      expect(bad_prompt).not_to be_valid
    end
  end

  # =========================================================================
  # 2. SPEAKING PROMPT SCHEMA DATA COMPILING TESTS
  # =========================================================================
  describe "Speaking Prompt Validations" do
    it "allows a valid speaking task containing a photo asset URL and a targeted short question to save cleanly" do
      prompt = Prompt.new(
        level: b2_level,
        prompt_type: "speaking",
        title: "Describe this holiday photo",
        topic: "tourism", # ✅ Topic applies flawlessly here too!
        metadata: {
          "image_url" => "https://rennladacademy.com",
          "question" => "Compare these two family holiday destinations and explain what benefits they bring to local economies."
        }
      )

      expect(prompt).to be_valid
      expect(prompt.topic).to eq("tourism")
      expect(prompt.question).to include("Compare these two family holiday")
    end

    it "strictly blocks speaking prompts that are missing a prompt question text string" do
      bad_speaking = Prompt.new(
        level: b2_level,
        prompt_type: "speaking",
        title: "Missing question text block",
        topic: "hobbies",
        metadata: { "image_url" => "https://localhost/test.jpg" }
      )

      expect(bad_speaking).not_to be_valid
      expect(bad_speaking.errors[:metadata]).to include("must include a speaking prompt question text string")
    end
  end
end
