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



  # POST /api/v1/questions/:id/submit_answer
  def submit_answer
    @question = Question.find(params[:id])

    # Strip whitespace and make lowercase for case-insensitive verification
    submitted_raw = params[:answer].to_s.strip
    submitted = submitted_raw.downcase

    # Normalize your DB answers array to lowercase for an accurate comparison
    is_correct = @question.answers.map { |ans| ans.to_s.strip.downcase }.include?(submitted)

    # Use increment! to safely skip model validations and instantly hit the DB
    @question.increment!(:attempted)
    @question.increment!(:correct) if is_correct

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

    # Correct way to return a blank response to the frontend
    head :no_content

  rescue ActiveRecord::RecordNotFound
    render json: { error: "Question not found" }, status: :not_found
  end





  private

  # Helper method to shape the response based on the puzzle type
  def format_response(question)
    # Base payload structure
    base = { id: question.id, kind: question.kind, subtype: question.subtype, main: question.main, answers: question.answers, tags: question.tags.map(&:name) }

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
