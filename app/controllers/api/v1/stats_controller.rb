# app/controllers/api/v1/stats_controller.rb
# =========================================================================
# STATELESS API V1 STUDENT METRICS FEED CONTROLLER
# - Inherits from ApiController to ensure token-isolated profile extractions
# - Computes real-time daily session deltas and charts historic timelines
# - Maps raw relational score integers back to descriptive category keys
# =========================================================================
class Api::V1::StatsController < ApiController
  # --- Action Lifecycle Filters ---
  # Replaces manual if-checks with our centralized parent gate filter
  before_action :authenticate_api_user!

  # --- Action Endpoints ---

  # GET /api/v1/stats
  def show
    user = current_user

    # 1. COMPUTE DAILY SESSION DELTA VARIANCE
    # Locates the newest archival snapshot record stored prior to today's date
    yesterday_snapshot = user.elo_snapshots.where("recorded_on < ?", Date.current).order(recorded_on: :desc).first

    # Fall back to baseline 1200 if this represents a student's first active day
    baseline_rating = yesterday_snapshot ? yesterday_snapshot.rating : 1200
    daily_elo_change = user.rating - baseline_rating

    # 2. MAP HISTORIC PROGRESS CHART TIMELINES
    history_timeline = user.elo_snapshots.order(recorded_on: :asc).map do |snapshot|
      {
        date: snapshot.recorded_on.to_s,
        rating: snapshot.rating
      }
    end

    # 3. COMPILE RESPONSE MATRIX
    render json: {
      global_rating: user.rating,
      daily_delta: daily_elo_change,
      elo_history: history_timeline,
      puzzle_types: format_category_stats(user, "kind", Question.kinds),
      subtypes: format_category_stats(user, "subtype", Question.subtypes),
      tags: user.user_tag_stat&.stats_json || {}
    }, status: :ok
  end

  private

  # Structural helper mapping raw database matrix integers back to human-readable strings
  def format_category_stats(user, type_string, enum_mapping)
    stats_hash = {}

    # Initialize a safe schema fallback structure for every system key to prevent client UI crashes
    enum_mapping.keys.each do |key|
      stats_hash[key] = { "done" => 0, "correct" => 0, "rating" => 1200 }
    end

    # Scans and populates metrics records found inside the student's statistics logs
    user.user_stats.where(stat_type: type_string).each do |stat|
      key_name = enum_mapping.key(stat.stat_key)

      if key_name.present?
        stats_hash[key_name] = {
          "done" => stat.times_done,
          "correct" => stat.times_correct,
          "rating" => stat.rating
        }
      end
    end

    stats_hash
  end
end
