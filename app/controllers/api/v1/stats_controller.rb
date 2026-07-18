class Api::V1::StatsController < ApiController
  # GET /api/v1/stats
  def show
    user = current_user

    if user.nil?
      render json: { error: "Unauthorized" }, status: :unauthorized
      return
    end

    # ✅ COMPUTE DAILY SESSION DELTA
    # Find the newest snapshot recorded *prior* to the current calendar date
    yesterday_snapshot = user.elo_snapshots.where("recorded_on < ?", Date.current).order(recorded_on: :desc).first

    # If they have no previous snapshots (e.g. brand new user), their baseline is their initial 1200
    baseline_rating = yesterday_snapshot ? yesterday_snapshot.rating : 1200
    daily_elo_change = user.rating - baseline_rating

    history_timeline = user.elo_snapshots.order(recorded_on: :asc).map do |snapshot|
      {
        date: snapshot.recorded_on.to_s,
        rating: snapshot.rating
      }
    end

    render json: {
      global_rating: user.rating,
      # ✅ NEW V2 ATTRIBUTE: Feeds your React analytics dashboard counters directly
      daily_delta: daily_elo_change,
      elo_history: history_timeline,
      puzzle_types: format_stats(user, "kind", Question.kinds),
      subtypes: format_stats(user, "subtype", Question.subtypes),
      tags: user.user_tag_stat&.stats_json || {}
    }
  end

  private

  # Helper method to map raw integer scores back to their human-readable keys
  def format_stats(user, type_string, enum_mapping)
    stats_hash = {}

    enum_mapping.keys.each do |key|
      stats_hash[key] = { done: 0, correct: 0, rating: 1200 }
    end

    user.user_stats.where(stat_type: type_string).each do |stat|
      key_name = enum_mapping.key(stat.stat_key)

      if key_name.present?
        stats_hash[key_name] = {
          done: stat.times_done,
          correct: stat.times_correct,
          rating: stat.rating
        }
      end
    end

    stats_hash
  end
end
