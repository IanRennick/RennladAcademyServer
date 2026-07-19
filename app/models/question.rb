# app/models/question.rb
# =========================================================================
# SYSTEM MASTER POLYMORPHIC GRAMMAR & VOCABULARY PUZZLE REGRID MODEL
# - Maps multiple curriculum test configurations (Multiple Choice, Cloze, etc.)
# - Manages dynamic category validations, string tag list attributes, and Ransack text casting
# - Houses the system multi-part submission evaluation grading strings engine
# =========================================================================
class Question < ApplicationRecord
  # --- Attributes & Virtual Parameters ---
  # Allows form threads to pass a comma-separated string to build relational tags
  attr_accessor :tag_list

  # --- Enum Configurations ---
  enum :kind, { multiple_choice: 0, open_cloze: 1, word_formation: 2, sentence_cloze: 3 }

  enum :subtype, {
    mc_phrasal: 0, mc_collocation: 1, oc_phrasal: 2, oc_auxiliary: 3, wf_noun: 4, wf_verb: 5,
    sc_conditional: 6, sc_passive: 7, oc_determiner: 8, oc_preposition: 9, wf_adverb: 10,
    sc_reported_speech: 11, sc_unreal_past: 12, sc_structure_change: 13, sc_tense_change: 14,
    sc_intensifiers: 15, sc_modals: 16, sc_fixed_expression: 17, sc_verb_patterns: 18,
    sc_stative_verbs: 19, sc_relative_clauses: 20, sc_phrasal: 21, sc_linkers: 22,
    sc_comparisons: 23, sc_quantifier: 24, oc_linkers: 25, oc_relative_pronoun: 26,
    oc_article: 27, oc_as_like: 28, oc_negation: 29, oc_inversion: 30, oc_causative: 31,
    oc_fixed_expressions: 32, oc_comparison: 33, oc_quantifier: 34, oc_conditional: 35,
    mc_definition: 36, mc_linkers: 37, mc_quantifier: 38, mc_fixed_expressions: 39,
    mc_dependence: 40, wf_adjective: 41
  }

  # --- Structural Matrix Constraints ---
  # Authoritative lookup tree organizing which sub-topics belong to which parent kind
  SUBTYPES_BY_KIND = {
    "multiple_choice" => [ :mc_phrasal, :mc_collocation, :mc_definition, :mc_linkers, :mc_quantifier, :mc_fixed_expressions, :mc_dependence ],
    "open_cloze"      => [ :oc_phrasal, :oc_auxiliary, :oc_determiner, :oc_preposition, :oc_linkers, :oc_relative_pronoun, :oc_article, :oc_as_like, :oc_negation, :oc_inversion, :oc_causative, :oc_fixed_expressions, :oc_comparison, :oc_quantifier, :oc_conditional ],
    "word_formation"  => [ :wf_noun, :wf_verb, :wf_adverb, :wf_adjective ],
    "sentence_cloze"  => [ :sc_conditional, :sc_passive, :sc_reported_speech, :sc_unreal_past, :sc_structure_change, :sc_tense_change, :sc_intensifiers, :sc_modals, :sc_fixed_expression, :sc_verb_patterns, :sc_stative_verbs, :sc_relative_clauses, :sc_phrasal, :sc_linkers, :sc_comparisons, :sc_quantifier ]
  }.freeze

  # --- Associations ---
  has_many :comments, as: :commentable, dependent: :destroy
  has_many :wrong_answers, dependent: :destroy
  has_many :question_tags, dependent: :destroy
  has_many :tags, through: :question_tags
  has_many :user_histories, dependent: :destroy
  belongs_to :level

  # --- Lifecycle Callback Hooks ---
  after_initialize :set_defaults, if: :new_record?
  before_validation :clean_array_whitespace_nodes
  before_create :set_initial_elo_from_level
  before_save :assign_tags

  # --- Validations ---
  validates :main, presence: true
  validates :kind, presence: true
  validates :times_done, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :times_correct, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :rating, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  validate :subtype_must_match_kind
  validate :answers_array_cannot_be_empty

  # --- Ransack Custom Cast Properties ---
  # Casts complex JSON database fields into text parameters so Ransack can parse them in search strings
  ransacker :options_as_text do
    Arel.sql("CAST(questions.options AS TEXT)")
  end

  ransacker :answers_as_text do
    Arel.sql("CAST(questions.answers AS TEXT)")
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "id", "main", "prompt", "keyword", "subtype", "kind", "rating", "options_as_text", "answers_as_text" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "tags", "level" ]
  end

  # --- Instance Level Core Logical Methods ---

  # Converts the question's active tags into a single text block to populate form fields
  def tag_list
    tags.map(&:name).join(", ")
  end

  # SPRINT EVALUATION ENGINE: Validates student entries against whitelisted keys case-insensitively
  def score_flat_submission(submitted_text)
    raw_input = submitted_text.to_s.strip.downcase
    return 0.0 if raw_input.blank?

    cleaned_answers = Array(answers).map { |ans| ans.to_s.strip.downcase }.reject(&:blank?)
    return 0.0 if cleaned_answers.empty?

    cleaned_answers.include?(raw_input) ? 1.0 : 0.0
  end

  private

  # Filters empty padding strings out of your database storage parameters
  def clean_array_whitespace_nodes
    self.options = options.reject(&:blank?) if options.is_a?(Array)
    self.answers = answers.reject(&:blank?) if answers.is_a?(Array)
  end

  # Blocks database compilation loops if a subtopic does not map to its parent architecture
  def subtype_must_match_kind
    return if subtype.blank?

    allowed_subtypes = SUBTYPES_BY_KIND[kind]
    if allowed_subtypes.nil? || !allowed_subtypes.include?(subtype.to_sym)
      errors.add(:subtype, "is not a system-supported category for a #{kind.humanize} puzzle type")
    end
  end

  def answers_array_cannot_be_empty
    if Array(answers).reject(&:blank?).empty?
      errors.add(:answers, "matrix array cannot be empty; a valid question requires at least one core correct key string")
    end
  end

  def set_defaults
    self.times_done ||= 0
    self.times_correct ||= 0
    self.rating ||= 1200 # System global baseline Elo fallback parameter
  end

  # Parses tag_list virtual attributes to find-or-create standard lowercase tags
  def assign_tags
    return if @tag_list.blank?

    tag_names = @tag_list.split(",").map { |name| name.to_s.strip.downcase.gsub(/\A#+/, "").gsub(/[^a-z0-9_\-]/, "") }.uniq.reject(&:blank?)
    self.tags = tag_names.map { |name| Tag.find_or_create_by!(name: name) }
  end

  # Syncs difficulty profiles with our CEFR rating calibrations on creation
  def set_initial_elo_from_level
    if level.present? && level.initial_rating.present?
      self.rating = level.initial_rating
    end
  end
end
