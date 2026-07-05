class Api::V1::StatsController < ApiController
  # GET /api/v1/stats
  def show
    user = current_user # Your Doorkeeper token helper

    if user.nil?
      render json: { error: "Unauthorized" }, status: :unauthorized
      return
    end

    render json: {
      # 1. Structure the Core Type scores (e.g. Multiple Choice, Open Cloze)
      puzzle_types: format_stats(user, "kind", Question.kinds),

      # 2. Structure the Subtype scores
      subtypes: format_stats(user, "subtype", Question.subtypes),

      # 3. Pull the dynamic tags map directly from your JSON column
      tags: user.user_tag_stat&.stats_json || {}
    }
  end

  private

  # Helper method to map raw integer scores back to their human-readable keys
  def format_stats(user, type_string, enum_mapping)
    stats_hash = {}

    # Pre-populate all available enums with zeros so the frontend doesn't get empty data
    enum_mapping.keys.each do |key|
      stats_hash[key] = { done: 0, correct: 0 }
    end

    # Fetch the actual user data from the database
    user.user_stats.where(stat_type: type_string).each do |stat|
      # Translate the raw database integer back to the word (e.g. 0 -> "multiple_choice")
      key_name = enum_mapping.key(stat.stat_key)

      if key_name.present?
        stats_hash[key_name] = {
          done: stat.times_done,
          correct: stat.times_correct
        }
      end
    end

    stats_hash
  end
end
