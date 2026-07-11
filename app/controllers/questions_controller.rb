class QuestionsController < ApplicationController
  before_action :set_question, only: %i[ show ]

  # GET /questions or /questions.json
  def index
    @questions = Question.all.includes([ :level ])
  end

  def multiple_choices
    # Get all multiple Choices
    @questions = Question.where(kind: Question.kinds[:multiple_choice]).includes([ :level ])
  end

  def open_clozes
    # Get all open CLozes
    @questions = Question.where(kind: Question.kinds[:open_cloze]).includes([ :level ])
  end

  def word_formations
    # Get all multiple Choices
    @questions = Question.where(kind: Question.kinds[:word_formation]).includes([ :level ])
  end

  def sentence_clozes
    # Get all sentence clozes
    @questions = Question.where(kind: Question.kinds[:sentence_cloze]).includes([ :level ])
  end

  # GET /questions/1 or /questions/1.json
  def show
    @comments = @question.comments.root_threads.includes(:user)
  end


  private
    # Use callbacks to share common setup or constraints between actions.
    def set_question
      @question = Question.find(params.expect(:id))
    end
end
