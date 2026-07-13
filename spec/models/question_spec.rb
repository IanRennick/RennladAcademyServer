require 'rails_helper'

RSpec.describe Question, type: :model do
  # Setup valid baseline items to satisfy database constraints
  let!(:b2_level) { Level.find_or_create_by!(name: "B2") { |l| l.initial_rating = 1200 } }
  let!(:c1_level) { Level.find_or_create_by!(name: "C1") { |l| l.initial_rating = 1500 } }

  # 1. Core relationship checks
  describe "associations" do
    it { should belong_to(:level).optional }
    it { should have_many(:wrong_answers).dependent(:destroy) }
    it { should have_many(:question_tags).dependent(:destroy) }
    it { should have_many(:tags).through(:question_tags) }
    it { should have_many(:user_histories).dependent(:destroy) }
  end

  # 2. Test input filtering data arrays
  describe "callbacks and cleanups" do
    it "filters out empty form input strings from options and answers arrays before saving" do
      question = Question.new(
        kind: :multiple_choice,
        level: b2_level,
        main: "Choose the correct phrasal verb",
        options: [ "give up", "give in", "", "  " ],
        answers: [ "give up", "" ]
      )

      question.save!
      expect(question.options).to eq([ "give up", "give in" ])
      expect(question.answers).to eq([ "give up" ])
    end

    it "automatically inherits the initial_rating from its assigned level on creation" do
      question = Question.create!(
        kind: :multiple_choice,
        level: c1_level, # C1 level starts at 1500
        main: "Complete the text",
        options: [ "A", "B" ],
        answers: [ "A" ]
      )

      expect(question.rating).to eq(1500)
    end
  end

  # 3. Test dynamic comma-separated string tagging
  it "converts a comma-separated string into actual database tag attachments" do
      Tag.create!(name: "grammar")

      question = Question.new(
        kind: :open_cloze,
        level: b2_level, # ✅ Add this line to pass the database constraint
        main: "Complete the text.",
        answers: [ "the" ]
      )

      question.tag_list = "Grammar,  Phrasal_Verb, B2_Level, "
      question.save!

      expect(question.tags.map(&:name)).to match_array([ "grammar", "phrasal_verb", "b2_level" ])
      expect(Tag.count).to eq(3)
    end

  # 4. Test Cross-Category Validation Guards
  describe "subtype boundary validations" do
    it "allows a valid matching subtype to be saved successfully" do
      question = Question.new(
        kind: :multiple_choice,
        subtype: :mc_phrasal,
        level: b2_level,
        main: "He decided to ___ smoking.",
        options: [ "give up", "take up" ],
        answers: [ "give up" ]
      )

      expect(question).to be_valid
    end

    it "blocks saving if an admin tries to attach a mismatched subtype" do
      question = Question.new(
        kind: :multiple_choice,
        subtype: :wf_noun, #  Mismatched: wf_noun belongs strictly to word_formation
        main: "Mismatched testing schema sample text.",
        options: [ "A", "B" ],
        answers: [ "A" ]
      )

      expect(question).to_not be_valid
      expect(question.errors[:subtype]).to include("is not valid for a Multiple choice puzzle")
    end
  end
end
