# app/controllers/questions_controller.rb
class QuestionsController < ApplicationController
  def index
    # 1. Initialize Ransack Search Engine with eager loading to prevent N+1 bugs
    @query = Question.ransack(params[:q])

    # ✅ FIX FOR POSTGRES: Filter row IDs to eliminate JSON comparison crashes completely
    distinct_ids = @query.result.pluck(:id).uniq

    # Apply Pagy pagination to your clean collection of eager-loaded rows
    @pagy, @questions = pagy(
      Question.where(id: distinct_ids).includes(:level).order(created_at: :desc),
      items: 25
    )

    # 3. Calculate Global & CEFR Level Balance Metrics (Aggregated in 1 SQL query)
    @total_count = Question.count
    @level_counts = Question.joins(:level).group("levels.name").count # e.g., {"B2"=>150, "C1"=>120}

    # 4. Calculate Question Kinds Balance Metrics
    @kind_counts = Question.group(:kind).count # e.g., {"multiple_choice"=>150, "open_cloze"=>100}

    # 5. Extract Subtype Balance Metrics (Skipping nil profiles)
    @subtype_counts = Question.where.not(subtype: nil).group(:kind, :subtype).count # e.g., {["multiple_choice", "mc_phrasal"] => 90}

    # 6. Extract ALL active database tags sorted alphabetically by name
    @all_tags = Tag.joins(:question_tags)
                   .group(:name)
                   .order("name ASC") # Alphabetical order makes finding tags incredibly easy!
                   .count
  end

  def show
    @question = Question.find(params[:id])
    @comments = @question.comments.root_threads.includes(:user)
  end
end
