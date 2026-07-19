# app/controllers/questions_controller.rb
# =========================================================================
# CENTRAL CURRICULUM POOL & PUZZLE DOSSIER CONTROLLER
# - Computes high-density database inventory balance counts and tag distributions
# - Integrates Pagy block limits and handles asynchronous forum comments threads
# - Inherits global search query variables from the parent ApplicationController
# =========================================================================
class QuestionsController < ApplicationController
  # --- Action Filter Endpoints ---

  # GET /questions
  def index
    # 1. POLYMORPHIC QUESTION SEARCH PIPELINE
    # Inherits the global '@query' instance cleanly from the parent ApplicationController filter
    distinct_ids = @query.result.pluck(:id).uniq

    # Apply Pagy pagination bounds to the clean collection of eager-loaded records
    @pagy, @questions = pagy(
      Question.where(id: distinct_ids).includes(:level).order(created_at: :desc),
      items: 25
    )

    # 2. CURRICULUM TOPOLOGY INVENTORY STOCKS METRICS
    @total_count = Question.count

    # PERFORMANCE OPTIMIZATION: Shifted to left_outer_joins to guarantee absolute structural
    # inventory numbers even if an orphaned difficulty parameter passes through
    @level_counts = Question.left_outer_joins(:level).group("levels.name").count

    # Calculate question types and subcategory footprints distribution blocks
    @kind_counts    = Question.group(:kind).count
    @subtype_counts = Question.where.not(subtype: nil).group(:kind, :subtype).count

    # Extract all active grammar search tags sorted alphabetically to build the admin tag clouds
    @all_tags = Tag.joins(:question_tags)
                   .group(:name)
                   .order("name ASC")
                   .count
  end

  # GET /questions/:id
  def show
    # Scoped database find path handles record extraction
    @question = Question.find(params[:id])

    # Eager-loads user profiles inside discussion threads to prevent nested N+1 data leaks
    @comments = @question.comments.root_threads.includes(:user)
  end
end
