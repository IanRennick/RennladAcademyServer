class SearchController < ApplicationController
  def index
    # 1. Question Search Engine
    @query = Question.ransack(params[:q])
    @questions = @query.result(distinct: true).includes(:level, :tags)

    # 2. User Omni-Search Engine
    search_term = params.dig(:q, :main_or_prompt_or_keyword_or_options_as_text_or_answers_as_text_or_tags_name_i_cont_any) || params[:search_term]

    if search_term.present?
      # FIX: Use strict lowercase casting on both database columns and the search term
      clean_term = "%#{search_term.strip.downcase}%"
      @users = User.where("lower(username) LIKE ? OR lower(email) LIKE ?", clean_term, clean_term)
                   .order(rating: :desc)
    else
      @users = User.order(rating: :desc)
    end
  end
end
