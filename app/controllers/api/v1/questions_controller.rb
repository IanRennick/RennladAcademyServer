class Api::V1::QuestionsController < ApiController
  def random
    # Filter by primary type if provided
    if params[:type].present?
      resolved_type = params[:type].match?(/\A\d+\z/) ? Question.kinds.key(params[:type].to_i) : params[:type]
      questions = questions.where(kind: resolved_type)
    end

    # Filter by subtype if provided
    if params[:subtype].present?
      resolved_subtype = params[:subtype].match?(/\A\d+\z/) ? Question.subtypes.key(params[:subtype].to_i) : params[:subtype]
      questions = questions.where(subtype: resolved_subtype)
    end

    # Use database-level random sampling for better performance than .all.sample
    @question = questions.order("RANDOM()").first

    if @question
      render json: format_response(@question)
    else
      render json: { error: "No questions found" }, status: :not_found
    end
  end

  private

  # Helper method to shape the response based on the puzzle type
  def format_response(question)
    # Base payload structure
    base = { id: question.id, kind: question.kind, subtype: question.subtype, main: question.main, answers: question.answers }

    case question.kind

    # Multiple Choice response:
    when "multiple_choice"
      { options: question.options }

    # Open Cloze response:
    when "open_cloze"
      {}

    # Word Formation response:
    when "word_formation"
      { keyword: question.keyword }

    # Sentence Cloze response:
    when "sentence_cloze"
      { keyword: question.keyword, prompt: question.prompt }

    # Fallback response:
    else
      base
    end
  end
end
