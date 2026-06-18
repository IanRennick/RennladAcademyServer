class Api::V1::QuestionsController < ApiController
  # GET /questions or /questions.json
  def random
    # Return random question
    @question = Question.all.sample(1)
    render json: @question.first
  end

  def multiple_choice
    # Get all multiple Chices
    @question = Question.where(kind: Question.kinds[:multiple_choice]).sample(1)
    render json: @question.first
  end

  def open_cloze
    # Get all open CLozes
    @question = Question.where(kind: Question.kinds[:open_cloze]).sample(1)
    render json: @question.first
  end

  def word_formation
    # Get all multiple Choices
    @question = Question.where(kind: Question.kinds[:word_formation]).sample(1)
    render json: @question.first
  end

  def sentence_cloze
    # Get all sentence clozes
    @question = Question.where(kind: Question.kinds[:sentence_cloze]).sample(1)
    render json: @question.first
  end
end
