class Question < ApplicationRecord
  before_save :clean_data

  # Different exam question types
  enum :kind, { multiple_choice: 0, open_cloze: 1, word_formation: 2, sentence_cloze: 3 }

  # Associate with Comments
  has_many :comments, as: :commentable, dependent: :destroy

  # Allows the form to pass a custom string method
  attr_accessor :tag_list

  # Run this right before saving to assign the tags safely
  before_save :assign_tags

  # Define all possible subtypes as a flat enum list mapping to integers
  enum :subtype, {
    mc_phrasal_verb: 0,
    mc_collocation: 1,
    oc_phrasal_verb: 2,
    oc_auxiliary_verb: 3,
    wf_noun: 4,
    wf_verb: 5,
    sc_conditional: 6,
    sc_passive: 7,
    oc_determiner: 8,
    oc_preposition: 9,
    wf_adverb: 10,
    sc_reported_speech: 11,
    sc_hypothetical: 12
  }


  # A map to organize which subtypes belong to which kind
  SUBTYPES_BY_KIND = {
    "multiple_choice" => [ :mc_phrasal_verb, :mc_collocation ],
    "open_cloze"      => [ :oc_phrasal_verb, :oc_auxiliary_verb, :oc_determiner, :oc_preposition ],
    "word_formation"  => [ :wf_noun, :wf_verb, :wf_adverb ],
    "sentence_cloze"  => [ :sc_conditional, :sc_passive, :sc_reported_speech, :sc_hypothetical ]
  }.freeze

  validate :subtype_must_match_kind


  has_many :wrong_answers, dependent: :destroy

  # Ensure tracking integers default to zero instead of nil
  after_initialize :set_defaults, if: :new_record?

  # Tagging system
  has_many :question_tags, dependent: :destroy
  has_many :tags, through: :question_tags

  # This allows your edit form to pre-populate with the existing tags as a string
  def tag_list
    tags.map(&:name).join(", ")
  end

  has_many :user_histories, dependent: :destroy

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
    self.attempted ||= 0
    self.correct ||= 0
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
end
