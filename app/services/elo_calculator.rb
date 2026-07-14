class EloCalculator
  BASE_K_FACTOR = 32
  PROVISIONAL_K_FACTOR = 64

  def self.calculate(user_rating, question_rating, user_won, user_total_completed = 25, question_total_completed = 25)
    # ✅ FIX: Change 400 to 400.0 to guarantee high-precision float division!
    expected_user = 1.0 / (1.0 + 10.0**((question_rating - user_rating) / 400.0))

    actual_user =
      case user_won
      when true then 1.0
      when false then 0.0
      else user_won.to_f
      end

    user_k = user_total_completed < 20 ? PROVISIONAL_K_FACTOR : BASE_K_FACTOR
    question_k = question_total_completed < 20 ? PROVISIONAL_K_FACTOR : BASE_K_FACTOR

    user_change = (user_k * (actual_user - expected_user)).round
    question_change = (question_k * (expected_user - actual_user)).round

    [ user_rating + user_change, question_rating + question_change ]
  end
end
