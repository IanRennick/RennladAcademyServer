class SearchController < ApplicationController
  def index
    @query = Question.ransack(params[:q])

    @questions = @query.result(distinct: true).includes(:level)
  end
end
