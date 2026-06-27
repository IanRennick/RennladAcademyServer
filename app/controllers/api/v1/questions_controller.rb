class Api::V1::QuestionsController < ApiController
  def random
    # Fetch questions filtered by type if provided, otherwise fetch all
    questions = params[:type].present? ? Question.where(kind: params[:type]) : Question.all

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
    case question.kind

    # Multiple Choice response:
    when "multiple_choice"
      { id: question.id, kind: question.kind, main: question.main, options: question.options, answer: question.answer }

    # Open Cloze response:
    when "open_cloze"
      { id: question.id, kind: question.kind, main: question.main, answer: question.answer }

    # Word Formation response:
    when "word_formation"
      { id: question.id, kind: question.kind, main: question.main, answer: question.answer, keyword: question.keyword }

    # Sentence Cloze response:
    when "sentence_cloze"
      { id: question.id, kind: question.kind, main: question.main, answer: question.answer, keyword: question.keyword, prompt: question.prompt }

    # Fallback response:
    else
      question.as_json
    end
  end
end
