class Question < ApplicationRecord
  before_save :clean_data
  before_create :set_initial_elo_from_level

  # Different exam question types
  enum :kind, { multiple_choice: 0, open_cloze: 1, word_formation: 2, sentence_cloze: 3 }

  # Associations with comments, wrong answers, tags, user history
  has_many :comments, as: :commentable, dependent: :destroy
  has_many :wrong_answers, dependent: :destroy
  has_many :question_tags, dependent: :destroy
  has_many :tags, through: :question_tags
  has_many :user_histories, dependent: :destroy
  belongs_to :level, optional: true


  # Allows the form to pass a custom string method
  attr_accessor :tag_list

  # Run this right before saving to assign the tags safely
  before_save :assign_tags

  # Define all possible subtypes as a flat enum list mapping to integers
  enum :subtype, {
    mc_phrasal: 0,
    mc_collocation: 1,
    oc_phrasal: 2,
    oc_auxiliary: 3,
    wf_noun: 4,
    wf_verb: 5,
    sc_conditional: 6,
    sc_passive: 7,
    oc_determiner: 8,
    oc_preposition: 9,
    wf_adverb: 10,
    sc_reported_speech: 11,
    sc_unreal_past: 12,
    sc_structure_change: 13,
    sc_tense_change: 14,
    sc_intensifiers: 15,
    sc_modals: 16,
    sc_fixed_expression: 17,
    sc_verb_patterns: 18,
    sc_stative_verbs: 19,
    sc_relative_clauses: 20,
    sc_phrasal: 21,
    sc_linkers: 22,
    sc_comparisons: 23,
    sc_quantifier: 24,
    oc_linkers: 25,
    oc_relative_pronoun: 26,
    oc_article: 27,
    oc_as_like: 28,
    oc_negation: 29,
    oc_inversion: 30,
    oc_causative: 31,
    oc_fixed_expressions: 32,
    oc_comparison: 33,
    oc_quantifier: 34,
    oc_conditional: 35,
    mc_definition: 36,
    mc_linkers: 37,
    mc_quantifier: 38,
    mc_fixed_expressions: 39,
    mc_dependence: 40,
    wf_adjective: 41
  }


  # A map to organize which subtypes belong to which kind
  SUBTYPES_BY_KIND = {
    "multiple_choice" => [ :mc_phrasal, :mc_collocation, :mc_definition, :mc_linkers, :mc_quantifier, :mc_fixed_expressions, :mc_dependence ],
    "open_cloze"      => [ :oc_phrasal, :oc_auxiliary, :oc_determiner, :oc_preposition, :oc_linkers, :oc_relative_pronoun, :oc_article, :oc_as_like, :oc_negation, :oc_inversion, :oc_causative, :oc_fixed_expressions, :oc_comparison, :oc_quantifier, :oc_conditional ],
    "word_formation"  => [ :wf_noun, :wf_verb, :wf_adverb, :wf_adjective ],
    "sentence_cloze"  => [ :sc_conditional, :sc_passive, :sc_reported_speech, :sc_unreal_past, :sc_structure_change, :sc_tense_change, :sc_intensifiers, :sc_modals, :sc_fixed_expression, :sc_verb_patterns, :sc_stative_verbs, :sc_relative_clauses, :sc_phrasal, :sc_linkers, :sc_comparisons, :sc_quantifier ]
  }.freeze

  validate :subtype_must_match_kind



  # Ensure tracking integers default to zero instead of nil
  after_initialize :set_defaults, if: :new_record?



  # This allows your edit form to pre-populate with the existing tags as a string
  def tag_list
    tags.map(&:name).join(", ")
  end



  # Custom casting nodes to turn JSON arrays into searchable text blocks for Ransack
  ransacker :options_as_text do |parent|
    Arel.sql("CAST(questions.options AS TEXT)")
  end

  ransacker :answers_as_text do |parent|
    Arel.sql("CAST(questions.answers AS TEXT)")
  end

  # Whitelist attributes for security rules
  def self.ransackable_attributes(auth_object = nil)
    [ "id", "main", "prompt", "keyword", "subtype", "kind", "rating", "options_as_text", "answers_as_text" ]
  end

  # Whitelist associations for table joins
  def self.ransackable_associations(auth_object = nil)
    [ "tags", "level" ]
  end


  # ✅ V2 MULTI-PART EVALUATION ENGINE
  # Evaluates a flat C2 string submission and returns a fractional float score (0.0 to 1.0)
  def score_flat_submission(submitted_text)
    cleaned_input = submitted_text.to_s.strip.gsub(/\s+/, " ").downcase
    return 0.0 if cleaned_input.blank?

    best_fractional_score = 0.0

    # question.answers holds your array, e.g., ["no problem || solving", "little difficulty || in solving"]
    # Inside your score_flat_submission(submitted_text) method:
    answers.each do |combo|
      # ✅ FIX: Explicitly run strip on both elements to eliminate hidden whitespace mismatches completely
      blocks = combo.split("||").map { |b| b.to_s.strip.downcase }

      if blocks.size == 2
        block1, block2 = blocks[0], blocks[1]

        # Create a dynamic regex that expects block1, followed by spaces, followed by block2
        regex = /\A(?<b1>#{Regexp.escape(block1)})\s+(?<b2>#{Regexp.escape(block2)})\z/

        if (match = cleaned_input.match(regex))
          return 1.0
        end

        # ✅ With strip active, start_with? and end_with? will match your text perfectly!
        if cleaned_input.start_with?(block1)
          current_score = 0.5
        elsif cleaned_input.end_with?(block2)
          current_score = 0.5
        else
          current_score = 0.0
        end

        best_fractional_score = current_score if current_score > best_fractional_score
      else
        # Backward compatibility fallback for single-blank questions
        single_answer = combo.to_s.strip.downcase
        if cleaned_input == single_answer
          return 1.0
        end
      end
    end

    best_fractional_score
  end


  private

  def clean_data
    self.options = options.reject(&:blank?) if options.is_a?(Array)
    self.answers = answers.reject(&:blank?) if answers.is_a?(Array) # Clean answers array
  end

  def subtype_must_match_kind
    return if subtype.blank? # Skip if no subtype is selected

    # Check if the chosen subtype is allowed for the chosen kind
    allowed_subtypes = SUBTYPES_BY_KIND[kind]

    if allowed_subtypes.nil? || !allowed_subtypes.include?(subtype.to_sym)
      errors.add(:subtype, "is not valid for a #{kind.humanize} puzzle")
    end
  end

  def set_defaults
    self.times_done ||= 0
    self.times_correct ||= 0
  end

  def assign_tags
    return if @tag_list.blank?

    # 1. Break the string by commas, strip extra spaces, make lowercase, and remove duplicates
    tag_names = @tag_list.split(",").map { |name| name.strip.downcase }.uniq.reject(&:blank?)

    # 2. Find existing tags or initialize new ones, then assign them to the question
    self.tags = tag_names.map do |name|
      Tag.find_or_create_by!(name: name)
    end
  end

  def set_initial_elo_from_level
    # If the question was given a level, and that level has an initial rating, use it!
    if level.present? && level.initial_rating.present?
      self.rating = level.initial_rating
    end
  end
end
