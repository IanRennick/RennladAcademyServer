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
    question = Question.find(params[:id])
    submitted_text = params[:answer] || params[:submitted_text]
    mode_param = params[:mode] || params[:practice_mode]

    # 1. Run our V2 dynamic evaluation engine to calculate fractional scores
    score = question.score_flat_submission(submitted_text)
    is_fully_correct = (score == 1.0)

    # 2. Increment global question counters
    question.times_done += 1
    question.times_correct += 1 if is_fully_correct
    question.save!

    # 3. Log unique mistakes to wrong_answers table
    if !is_fully_correct && submitted_text.present?
      cleaned_wrong = submitted_text.to_s.strip.gsub(/\s+/, " ")
      wa = question.wrong_answers.find_or_initialize_by(answer_text: cleaned_wrong)
      wa.count += 1
      wa.save!
    end

    # 4. Handle the permanent UserHistory log row
    history = current_user.user_histories.find_or_initialize_by(question_id: question.id)
    if history.new_record?
      history.first_attempt_correct = is_fully_correct
      history.original_wrong_answer = submitted_text unless is_fully_correct
    end
    history.needs_review = !is_fully_correct
    history.save!

    # 5. Process Elo trajectories using positional arguments
    user_total_attempts = current_user.user_histories.count

    new_user_rating, new_question_rating = EloCalculator.calculate(
      current_user.rating,
      question.rating,
      score,
      user_total_attempts,
      question.times_done
    )

    # ✅ FIX: Explicitly restore the local variable assignment definition rule!
    is_practice = (mode_param == "practice" || (current_user.respond_to?(:practice_mode) && current_user.practice_mode))

    # Calculate what the targeted user-rating should be up-front
    target_user_rating = is_practice ? current_user.rating : new_user_rating

    # Commit rating updates to our primary models safely
    if is_practice
      question.update!(rating: new_question_rating)
    else
      current_user.update!(rating: target_user_rating)
      question.update!(rating: new_question_rating)
    end

    # 6. UPDATE KIND/SUBTYPE MATRIX (Runs exactly 1 time)
    kind_stat = current_user.user_stats.find_or_initialize_by(stat_type: "kind", stat_key: Question.kinds[question.kind])
    kind_stat.times_done += 1
    kind_stat.times_correct += 1 if is_fully_correct
    kind_stat.rating = target_user_rating
    kind_stat.save!

    if question.subtype.present?
      subtype_stat = current_user.user_stats.find_or_initialize_by(stat_type: "subtype", stat_key: Question.subtypes[question.subtype])
      subtype_stat.times_done += 1
      subtype_stat.times_correct += 1 if is_fully_correct
      subtype_stat.rating = target_user_rating
      subtype_stat.save!
    end

    # 7. UPDATE JSON TAG METRICS (Runs exactly 1 time)
    if current_user.respond_to?(:update_tag_metrics)
      tag_names = question.tags.map(&:name)
      current_user.update_tag_metrics(tag_names, question.rating, is_fully_correct)

      # Sync the nested JSON string tag elements explicitly with target ratings
      user_tag_record = current_user.user_tag_stat
      if user_tag_record && user_tag_record.stats_json.any?
        tag_names.each do |tag|
          if user_tag_record.stats_json[tag]
            user_tag_record.stats_json[tag]["rating"] = target_user_rating
          end
        end
        user_tag_record.save!
      end
    end

    # Return clean JSON summary data back to your React client view
    render json: {
      score: score,
      fully_correct: is_fully_correct,
      user_new_rating: current_user.rating,
      question_new_rating: question.rating
    }, status: :ok
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
