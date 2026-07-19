# app/controllers/search_controller.rb
# =========================================================================
# OMNI-SEARCH MULTI-MODEL ROUTER CONTROLLER
# - Coordinates unified text search query lookups across both Questions and Users
# - Leverages parent Ransack variables and indexed SQL fragments safely
# =========================================================================
class SearchController < ApplicationController
  # --- Action Filter Endpoints ---

  def index
    # 1. POLYMORPHIC QUESTION SEARCH PIPELINE
    # Inherits the global '@query' instance cleanly from the parent ApplicationController filter
    distinct_ids = @query.result.pluck(:id).uniq
    @questions = Question.where(id: distinct_ids).includes(:level)

    # 2. OMNI-STUDENT PROFILE SEARCH PIPELINE
    # Safely extracts keyword tokens from the unified search text field parameters
    search_term = params.dig(:q, :main_or_prompt_or_keyword_or_options_as_text_or_answers_as_text_or_tags_name_i_cont_any) || params[:search_term]

    if search_term.present?
      clean_term = "%#{search_term.to_s.strip.downcase}%"
      @users = User.where("lower(username) LIKE ? OR lower(email) LIKE ?", clean_term, clean_term)
                   .order(rating: :desc)
    else
      # OPTIMIZATION SECURITY SHIELD: Replaced heavy global scans with a fast empty active record collection
      @users = User.none
    end
  end
end
