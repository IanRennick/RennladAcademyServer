class EloCalculator
  # Standard k factor
  BASE_K_FACTOR = 32
  # Beginner k factor - less than 20 answered
  PROVISIONAL_K_FACTOR = 64

  def self.calculate(user_rating, question_rating, user_won, user_total_completed = 25, question_total_completed = 25)
    # 1. Compute probability (standard Elo math)
    expected_user = 1.0 / (1.0 + 10**((question_rating - user_rating) / 400.0))
    actual_user = user_won ? 1.0 : 0.0

    # 2. Dynamic Rule for User: Provisional if under 20 completed puzzles
    user_k = user_total_completed < 20 ? PROVISIONAL_K_FACTOR : BASE_K_FACTOR

    # 3. Dynamic Rule for Question: Provisional if under 20 total attempts globally
    question_k = question_total_completed < 20 ? PROVISIONAL_K_FACTOR : BASE_K_FACTOR

    # 4. Calculate points variance using their independent K-factors
    user_change = user_k * (actual_user - expected_user)
    question_change = question_k * (actual_user - expected_user)

    # 5. Compute and round out the new final database values (minimum floor of 100 Elo)
    new_user_rating = (user_rating + user_change).round
    new_question_rating = (question_rating - question_change).round

    [ [ new_user_rating, 100 ].max, [ new_question_rating, 100 ].max ]
  end
end
