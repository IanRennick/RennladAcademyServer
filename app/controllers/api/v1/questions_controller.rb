class Api::V1::QuestionsController < ApiController
  def random
    # 1. Start with a fallback to all questions so it can never be nil
    questions = Question.all
    type_param = params[:type]

    # 2. Filter by primary type if provided
    if type_param.present?
      # Resolve integer string ("1") to enum symbol, or use the string direct
      resolved_type = type_param.match?(/\A\d+\z/) ? Question.kinds.key(type_param.to_i) : type_param

      # Only filter if the type actually exists in our enum configuration
      if resolved_type.present? && Question.kinds.has_key?(resolved_type.to_s)
        questions = questions.where(kind: resolved_type)
      else
        # If an invalid type was sent, fallback to an empty ActiveRecord collection
        # instead of nil, so .order("RANDOM()") still safely works
        questions = Question.none
      end
    end

    # 3. Filter by subtype if provided
    if params[:subtype].present?
      subtype_param = params[:subtype]
      resolved_subtype = subtype_param.match?(/\A\d+\z/) ? Question.subtypes.key(subtype_param.to_i) : subtype_param

      if resolved_subtype.present? && Question.subtypes.has_key?(resolved_subtype.to_s)
        questions = questions.where(subtype: resolved_subtype)
      else
        questions = Question.none
      end
    end

    # 4. New: Filter by Tag if provided (e.g. ?tag=conditional)
    if params[:tag].present?
      # We clean up the parameter to lowercase to match our model creation rule
      tag_name = params[:tag].to_s.strip.downcase

      # .joins(:tags) looks through the join table to find matches securely
      questions = questions.joins(:tags).where(tags: { name: tag_name })
    end

    # 5. Filter by Level parameter if provided (e.g. ?level=b2)
    if params[:level].present?
      clean_level_name = params[:level].to_s.strip.upcase
      # Joins your level lookup table and securely extracts matching rows
      questions = questions.joins(:level).where(levels: { name: clean_level_name })
    end

    # Now questions is guaranteed to be an ActiveRecord Relation, never nil!
    @question = questions.order("RANDOM()").first

    if @question
      render json: format_response(@question)
    else
      render json: { error: "No questions found matching criteria" }, status: :not_found
    end
  end


  def show
    @question = Question.find(params[:id])

    # Reuse existing format_response method to shape the JSON
    render json: format_response(@question)
  rescue ActiveRecord::RecordNotFound
    # Safely handle the error if the frontend requests an ID that doesn't exist
    render json: { error: "Question not found" }, status: :not_found
  end



  def review_queue
    user = current_user # Uses your working API user helper

    if user.nil?
      render json: { error: "Unauthorized" }, status: :unauthorized
      return
    end

    # Gather questions where needs_review is true for this user
    # .includes(:tags) optimizes database lookups to keep things fast
    wrong_questions = Question.joins(:user_histories)
                              .where(user_histories: { user_id: user.id, needs_review: true })
                              .includes(:tags)

    # Pass every question through your unified format_response serializer layout
    formatted_queue = wrong_questions.map { |q| format_response(q) }

    render json: formatted_queue
  end



  # POST /api/v1/questions/:id/submit_answer
  def submit_answer
    @question = Question.find(params[:id])
    # Doorkeeper token lookup method
    user = current_user

    # Strip whitespace and make lowercase for case-insensitive verification
    submitted_raw = params[:answer].to_s.strip
    submitted = submitted_raw.downcase

    # Normalize your DB answers array to lowercase for an accurate comparison
    is_correct = @question.answers.map { |ans| ans.to_s.strip.downcase }.include?(submitted)

    # Check if the user requested practice mode
    is_practice_mode = params[:mode].to_s.strip.downcase == "practice"

    # 1. Run Core Overall Elo Math BEFORE saving any data increments
    old_q_rating = @question.rating
    if user.present?
      # Calculate global user total count using your puzzle-kind tracking row sum
      user_total = user.user_stats.where(stat_type: "kind").sum(:times_done).to_i

      # PASS BOTH total counts into the upgraded service now
      new_global_user_elo, new_global_q_elo = EloCalculator.calculate(
        user.rating,
        old_q_rating,
        is_correct,
        user_total,
        @question.times_done.to_i # Passes how many times this question was done historically
      )
    end

    # 2. Standard Global Question Updates
    @question.increment!(:times_done)
    @question.increment!(:times_correct) if is_correct
    if user.present?
      @question.update!(rating: new_global_q_elo)
    end

    unless is_correct
      # Find the row or build a new one
      wrong_log = @question.wrong_answers.find_or_initialize_by(answer_text: submitted_raw)

      if wrong_log.new_record?
        wrong_log.count = 1
        wrong_log.save # ✅ Saves a fresh new wrong answer to the database
      else
        wrong_log.increment!(:count) # ✅ Safely increments an existing record
      end
    end

    # 3. Update User Personal Metrics (Kind, Subtype & Tags, ELOS)
    if user.present?
      # A. Update Global User Elo
      unless is_practice_mode
        user.update!(rating: new_global_user_elo)
      end

      # B. Update Puzzle Kind Stat & Kind Elo
      kind_int = Question.kinds[@question.kind]
      kind_stat = user.user_stats.find_or_create_by!(stat_type: "kind", stat_key: kind_int)

      new_kind_user_elo, _ = EloCalculator.calculate(kind_stat.rating, old_q_rating, is_correct, kind_stat.times_done)
      kind_stat.increment!(:times_done)
      kind_stat.increment!(:times_correct) if is_correct
      kind_stat.update!(rating: new_kind_user_elo) unless is_practice_mode

      # C. Update Subtype Stat & Subtype Elo
      if @question.subtype.present?
        subtype_int = Question.subtypes[@question.subtype]
        subtype_stat = user.user_stats.find_or_create_by!(stat_type: "subtype", stat_key: subtype_int)

        new_sub_user_elo, _ = EloCalculator.calculate(subtype_stat.rating, old_q_rating, is_correct, subtype_stat.times_done)
        subtype_stat.increment!(:times_done)
        subtype_stat.increment!(:times_correct) if is_correct
        subtype_stat.update!(rating: new_sub_user_elo) unless is_practice_mode
      end

      # D. Update Tag Stats & Tag Elos
      if @question.tags.any?
        if is_practice_mode
          # Custom Practice Rule: Just increment the tag counts without altering tag Elo!
          stat_record = user.user_tag_stat || user.create_user_tag_stat(stats_json: {})
          current_json = stat_record.stats_json.dup
          @question.tags.map(&:name).each do |tag|
            current_json[tag] ||= { "done" => 0, "correct" => 0, "rating" => 1200 }
            current_json[tag]["done"] += 1
            current_json[tag]["correct"] += 1 if is_correct
          end
          stat_record.update!(stats_json: current_json)
        else
          # Standard Mode: Run the full Elo adjustments for tags
          user.update_tag_metrics(@question.tags.map(&:name), old_q_rating, is_correct)
        end
      end

      # E. User History Queue Trackers
      history = user.user_histories.find_by(question_id: @question.id)
      if history.nil?
        user.user_histories.create!(question_id: @question.id, first_attempt_correct: is_correct, needs_review: !is_correct, original_wrong_answer: is_correct ? nil : submitted_raw)
      elsif history.needs_review && is_correct
        history.update!(needs_review: false)
      end
    end


    # Correct way to return a blank response to the frontend
    head :no_content

  rescue ActiveRecord::RecordNotFound
    render json: { error: "Question not found" }, status: :not_found
  end





  private

  # Helper method to shape the response based on the puzzle type
  def format_response(question)
    # Translate the string representations into their raw database integer values
    kind_integer = Question.kinds[question.kind]
    subtype_integer = question.subtype ? Question.subtypes[question.subtype] : nil

    # Fetch only the main thread-starters (where parent_id is nil)
    root_comments = question.comments.root_threads.includes(:user)


    # Base payload structure
    base = { id: question.id, level: question.level&.name, kind: kind_integer, subtype: subtype_integer, main: question.main, answers: question.answers, tags: question.tags.map(&:name), comments: serialize_comments_tree(root_comments) }

    case question.kind

    # Multiple Choice response:
    when "multiple_choice"
      base.merge(options: question.options)

    # Open Cloze response:
    when "open_cloze"
      base

    # Word Formation response:
    when "word_formation"
      base.merge(keyword: question.keyword)

    # Sentence Cloze response:
    when "sentence_cloze"
      base.merge(keyword: question.keyword, prompt: question.prompt)

    # Fallback response:
    else
      base
    end
  end

  # Recursive Helper Method for Threaded Comments
  def serialize_comments_tree(comments_collection)
    comments_collection.map do |comment|
      {
        id: comment.id,
        parent_id: comment.parent_id,
        author: comment.user.username,
        body: comment.body.to_s, # Converts ActionText rich formatting to a clean HTML markup string!
        timestamp: comment.created_at.strftime("%b %d, %H:%M"),
        # Recursively crawls down to grab any sub-replies nested beneath this comment
        # Eager loads the sub-users to guarantee high-performance execution speed
        replies: serialize_comments_tree(comment.replies.includes(:user))
      }
    end
  end
end
