# app/services/elo_calculator.rb
# =========================================================================
# STATELESS CURRICULUM CALCULATOR SERVICE OBJECT
# - Executes logarithmic Elo scoring variations across questions and profiles
# - Supports fractional score values (1.0, 0.5, 0.0) for partial credit
# - Features provisional K-factor weight adaptations and sets an absolute 100 Elo floor
# =========================================================================
class EloCalculator
  # --- Mathematical Weight Parameters Constants ---
  BASE_K_FACTOR        = 32 # Standard configuration parameter for stable accounts
  PROVISIONAL_K_FACTOR = 64 # High-volatility modifier for newly created accounts

  # Primary mathematical calculation matrix endpoint
  def self.calculate(user_rating, question_rating, score, user_total_completed = 25, question_total_completed = 25)
    # 1. COMPUTE EXPECTED OUTCOME FRACTIONS (Logarithmic Logistic Curve)
    expected_user = 1.0 / (1.0 + 10**((question_rating - user_rating) / 400.0))

    # Read the fractional score payload directly to fully support V2 partial-credit grading math!
    actual_user = score.to_f

    # 2. DYNAMIC REGISTRATION SHIFT K-FACTORS
    user_k     = user_total_completed < 20 ? PROVISIONAL_K_FACTOR : BASE_K_FACTOR
    question_k = question_total_completed < 20 ? PROVISIONAL_K_FACTOR : BASE_K_FACTOR

    # 3. COMPUTE CALCULATED VARIANCE VALUES
    user_change     = user_k * (actual_user - expected_user)
    question_change = question_k * (actual_user - expected_user)

    # 4. ROUND PARAMETERS AND ENFORCE CRITICAL PLATFORM FLOORS
    new_user_rating     = (user_rating + user_change).round
    new_question_rating = (question_rating - question_change).round

    # Enforce an absolute lower limit floor of 100 Elo to prevent rating depletion crashes
    [ [ new_user_rating, 100 ].max, [ new_question_rating, 100 ].max ]
  end
end
