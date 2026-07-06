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

    # Use increment! to safely skip model validations and instantly hit the DB
    @question.increment!(:times_done)
    @question.increment!(:times_correct) if is_correct

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

    # 2. Update User Personal Metrics (Kind, Subtype & Tags)
    if user.present?
      # A. Core Question Type Tally (e.g. Multiple Choice, Open Cloze)
      kind_int = Question.kinds[@question.kind]
      kind_stat = user.user_stats.find_or_create_by!(stat_type: "kind", stat_key: kind_int)
      kind_stat.increment!(:times_done)
      kind_stat.increment!(:times_correct) if is_correct

      # B. Question Subtype Tally (Only runs if the puzzle has a subtype)
      if @question.subtype.present?
        subtype_int = Question.subtypes[@question.subtype]
        subtype_stat = user.user_stats.find_or_create_by!(stat_type: "subtype", stat_key: subtype_int)
        subtype_stat.increment!(:times_done)
        subtype_stat.increment!(:times_correct) if is_correct
      end

      # C. Tag Tally (Calculates nested elements inside the JSON file)
      if @question.tags.any?
        user.update_tag_metrics(@question.tags.map(&:name), is_correct)
      end

      # NEW LOGIC: User First-Try & Review Queue tracking
      # ----------------------------------------------------
      # Check if this user has ever attempted this question before
      history = user.user_histories.find_by(question_id: @question.id)

      if history.nil?
        # This is their FIRST ATTEMPT ever. Lock in the metrics forever.
        user.user_histories.create!(
          question_id: @question.id,
          first_attempt_correct: is_correct,
          needs_review: !is_correct, # Enters review queue if answer is incorrect
          original_wrong_answer: is_correct ? nil : submitted_raw
        )
      else
        # This is a REPEAT ATTEMPT.
        # If they are currently in the review queue and finally got it right, clear them!
        if history.needs_review && is_correct
          history.update!(needs_review: false)
        end
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

    # Base payload structure
    base = { id: question.id, kind: kind_integer, subtype: subtype_integer, main: question.main, answers: question.answers, tags: question.tags.map(&:name) }

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
end
