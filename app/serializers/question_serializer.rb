# app/serializers/question_serializer.rb
# =========================================================================
# STATELESS CURRICULUM QUESTIONS DATA SERIALIZER ENGINE
# - Shapes complex multi-dimensional question profiles into clean React payloads
# - Translates active text enums back to native database integer identifiers
# - Features a recursive traversal tree to compile infinitely nested forum comments
# =========================================================================
class QuestionSerializer
  attr_reader :question

  def initialize(question)
    @question = question
  end

  # Primary serialization execution point
  def as_json
    kind_integer = Question.kinds[question.kind]
    subtype_integer = question.subtype ? Question.subtypes[question.subtype] : nil
    root_comments = question.comments.root_threads.includes(:user)

    # Base payload structure shared across all layout formats
    base_payload = {
      id: question.id,
      level: question.level&.name,
      kind: kind_integer,
      subtype: subtype_integer,
      main: question.main,
      tags: question.tags.map(&:name),
      comments: serialize_comments_tree(root_comments)
    }

    # Dynamically inject type-specific context attributes matching your view blueprints
    case question.kind
    when "multiple_choice" then base_payload.merge(options: question.options)
    when "word_formation"  then base_payload.merge(keyword: question.keyword)
    when "sentence_cloze"  then base_payload.merge(keyword: question.keyword, prompt: question.prompt)
    else base_payload
    end
  end

  private

  # Recursive engine tracing downstream child replies without N+1 query leaks
  def serialize_comments_tree(comments_collection)
    comments_collection.map do |comment|
      {
        id: comment.id,
        parent_id: comment.parent_id,
        author: comment.user.username,
        body: comment.body.to_s, # Converts ActionText rich fragments to clean HTML text
        timestamp: comment.created_at.strftime("%b %d, %H:%M"),
        replies: serialize_comments_tree(comment.replies.includes(:user))
      }
    end
  end
end
