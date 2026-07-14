require 'rails_helper'

RSpec.describe "Api::V1::Questions", type: :request do
  # Add a default level record so your question creations don't break
  let!(:b2_level) { Level.find_or_create_by!(name: "B2") { |l| l.initial_rating = 1200 } }
  let!(:c1_level) { Level.find_or_create_by!(name: "C1") { |l| l.initial_rating = 1500 } }

  # Create a user and puzzle in test database
  let!(:user) { User.create!(username: "global_tester", email: "tester@example.com", password: "password123", password_confirmation: "password123") }

  let!(:question) do
    Question.create!(
      kind: :multiple_choice,
      subtype: :mc_phrasal,
      level: b2_level,
      main: "He decided to ___ smoking.",
      options: [ "give up", "take up", "look up" ],
      answers: [ "give up" ]
    )
  end

  # Mock a valid doorkeeper token for test requests
  before do
    # Allow the double to receive the hash-style lookup [:resource_owner_id]
    token = double(Doorkeeper::AccessToken, acceptable?: true)
    allow(token).to receive(:[]).with(:resource_owner_id).and_return(user.id)

    allow_any_instance_of(ApiController).to receive(:doorkeeper_token).and_return(token)
  end

  # Test getting a puzzle with an id
  describe "GET /api/v1/questions/:id" do
    context "when the question exists" do
      it "returns a successful 200 response with the correct custom JSON fields" do
        # Make a real GET request to your specific puzzle route
        get "/api/v1/questions/#{question.id}"

        # Verify the HTTP status code is 200 OK
        expect(response).to have_http_status(:ok)

        # Parse the returned JSON text string into a readable Ruby hash
        json = JSON.parse(response.body)

        # Verify the serialized structure matches `format_response` method
        expect(json["id"]).to eq(question.id)
        expect(json["level"]).to eq("B2")
        expect(json["main"]).to eq("He decided to ___ smoking.")
        expect(json["options"]).to eq([ "give up", "take up", "look up" ])
        expect(json["answers"]).to eq([ "give up" ])

        # Verify enums correctly translated back to integers
        expect(json["kind"]).to eq(0)
        expect(json["subtype"]).to eq(0)
      end
    end

    context "when the question does not exist" do
      it "returns a 404 Not Found error with your custom message" do
        # Request a dummy ID that definitely doesn't exist
        get "/api/v1/questions/999999"

        # Verify it dropped to rescue block status code
        expect(response).to have_http_status(:not_found)

        # Verify the error payload
        json = JSON.parse(response.body)
        expect(json["error"]).to eq("Question not found")
      end
    end
  end

  # Test getting a random puzzle and filters
  describe "GET /api/v1/questions/random" do
    # Create a new puzzle for testing
    let!(:word_formation_question) do
      Question.create!(
        kind: :word_formation,
        subtype: :wf_noun,
        level: c1_level,
        main: "Complete the sentence with the correct form of the word.",
        answers: [ "beautifully" ],
        keyword: "BEAUTY"
      )
    end

    # Test random puzzle without filters
    context "when no parameters are provided" do
      it "returns a successful 200 response with any random question" do
        get "/api/v1/questions/random"

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        # It should return either the multiple choice or word formation puzzle ID
        expect([ question.id, word_formation_question.id ]).to include(json["id"])
      end
    end

    # Test filtering by kind
    context "when filtering by a specific question kind integer string" do
      it "returns only questions that match that exact type" do
        # Trigger the filter with "2" (the integer value for word_formation)
        get "/api/v1/questions/random", params: { type: "2" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        # Verify it specifically pulled the Word Formation data structure
        expect(json["id"]).to eq(word_formation_question.id)
        expect(json["kind"]).to eq(2)
        expect(json["keyword"]).to eq("BEAUTY")
        expect(json).to_not have_key("options") # Hides option arrays for this type!
      end
    end

    # Test when a bad parameter is passed
    context "when an invalid type parameter is passed" do
      it "safely triggers your 404 fallback instead of throwing an error" do
        get "/api/v1/questions/random", params: { type: "99" }

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json["error"]).to eq("No questions found matching criteria")
      end
    end

    # Test filterng by subtype
    context "when filtering by a specific subtype integer string" do
      it "returns only questions that match that exact subtype" do
        # 0 is the integer value for :mc_phrasal
        get "/api/v1/questions/random", params: { subtype: "0" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json["id"]).to eq(question.id)
        expect(json["subtype"]).to eq(0)
      end
    end

    # Test filtering by tag
    context "when filtering by a specific tag string" do
      it "safely joins the tables and returns questions matching that tag" do
        # Create a tag and link it to word formation puzzle
        tag = Tag.create!(name: "vocabulary")
        word_formation_question.tags << tag

        # Query using mixed case to verify controller's .downcase cleaner
        get "/api/v1/questions/random", params: { tag: "VoCaBuLaRy" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json["id"]).to eq(word_formation_question.id)
        expect(json["tags"]).to include("vocabulary")
      end
    end
  end

  # Test getting review queue
  describe "GET /api/v1/questions/review_queue" do
    # Test when there are questions for review
    context "when a user has incorrect answers waiting for review" do
      it "returns a successful 200 response with only the questions needing review" do
        # Inject a wrong answer history row into the test database
        UserHistory.create!(
          user_id: user.id,
          question_id: question.id,
          first_attempt_correct: false,
          needs_review: true,
          original_wrong_answer: "look down"
        )

        # Call the endpoint
        get "/api/v1/questions/review_queue"

        # Validate the response
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json.is_a?(Array)).to eq(true)
        expect(json.length).to eq(1)
        expect(json.first["id"]).to eq(question.id)
        expect(json.first["main"]).to eq("He decided to ___ smoking.")
      end
    end

    # Test when there arent questions for review
    context "when a user has a clean slate and no mistakes" do
      it "returns a successful 200 response with an empty array" do
        get "/api/v1/questions/review_queue"

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json).to eq([])
      end
    end
  end

  # Test submitting an answer
  describe "POST /api/v1/questions/:id/submit_answer" do
    # Attach a tag to base question to test tag metrics tracking
    before do
      tag = Tag.create!(name: "grammar")
      question.tags << tag
    end

    # Test submitting a correct answer
    context "when the submitted answer is CORRECT" do
      it "returns a 204 No Content status and increments user and global metrics" do
        # Submit the correct answer string ("give up") matching the question model setup
        post "/api/v1/questions/#{question.id}/submit_answer", params: { answer: " GiVe uP  " } # Testing trim/case safety

        # Verify the HTTP response code is 204 No Content
        expect(response).to have_http_status(:ok)

        # Verify global tracking values incremented
        question.reload
        expect(question.times_done).to eq(1)
        expect(question.times_correct).to eq(1)

        # Verify User stats kind and subtype scoreboards updated
        kind_stat = user.user_stats.find_by(stat_type: "kind", stat_key: 0) # 0 = multiple_choice
        expect(kind_stat.times_done).to eq(1)
        expect(kind_stat.times_correct).to eq(1)
        expect(kind_stat.rating).to eq(1232)

        subtype_stat = user.user_stats.find_by(stat_type: "subtype", stat_key: 0) # 0 = mc_phrasal
        expect(subtype_stat.times_done).to eq(1)
        expect(subtype_stat.times_correct).to eq(1)

        # Verify Tag JSON scoreboard registered the win
        user.reload
        expect(user.user_tag_stat.stats_json["grammar"]).to eq({ "done" => 1, "correct" => 1, "rating" => 1232 })

        # Verify UserHistory logged a first-try success and left the review queue empty
        history = user.user_histories.find_by(question_id: question.id)
        expect(history.first_attempt_correct).to eq(true)
        expect(history.needs_review).to eq(false)
        expect(history.original_wrong_answer).to be_nil
      end
    end

    # Test submitting an incorrect answer
    context "when the submitted answer is INCORRECT" do
      it "increments done tallies, logs the unique mistake, and inserts the puzzle into the review queue" do
        # Submit an incorrect response string
        post "/api/v1/questions/#{question.id}/submit_answer", params: { answer: "look down" }

       expect(response).to have_http_status(:ok)

        # Verify global metrics reflect a failure
        question.reload
        expect(question.times_done).to eq(1)
        expect(question.times_correct).to eq(0)

        # Verify WrongAnswer analytics successfully recorded the specific trap text
        wrong_log = question.wrong_answers.find_by(answer_text: "look down")
        expect(wrong_log).to_not be_nil
        expect(wrong_log.count).to eq(1)

        # Verify user scoreboards reflect a miss
        kind_stat = user.user_stats.find_by(stat_type: "kind", stat_key: 0)
        expect(kind_stat.times_done).to eq(1)
        expect(kind_stat.times_correct).to eq(0)
        expect(kind_stat.rating).to eq(1168)

        user.reload
        expect(user.user_tag_stat.stats_json["grammar"]).to eq({ "done" => 1, "correct" => 0, "rating" => 1168 })

        # Verify UserHistory successfully triggered the review queue toggle switch
        history = user.user_histories.find_by(question_id: question.id)
        expect(history.first_attempt_correct).to eq(false)
        expect(history.needs_review).to eq(true)
        expect(history.original_wrong_answer).to eq("look down")
      end
    end

    # Test practice mode
    context "when answering in PRACTICE MODE" do
      it "increments all history logs and attempt counters, but leaves all Elo ratings unchanged" do
        # 1. Capture the exact Elo ratings before sending the request
        original_user_elo = user.rating
        original_q_elo = question.rating

        # 2. ACTION: Submit a correct answer but include the mode: "practice" query param
        post "/api/v1/questions/#{question.id}/submit_answer", params: { answer: "give up", mode: "practice" }

        expect(response).to have_http_status(:ok)

        # 3. ASSERTIONS: Verify global attempts incremented
        question.reload
        expect(question.times_done).to eq(1)
        expect(question.rating).to_not eq(original_q_elo) # The question rating HAS shifted to stay accurate!

        # 4. ASSERTIONS: Verify user stats incremented counters but froze ratings
        kind_stat = user.user_stats.find_by(stat_type: "kind", stat_key: 0)
        expect(kind_stat.times_done).to eq(1)
        expect(kind_stat.rating).to eq(1200) #  User rating remains frozen at baseline

        user.reload
        expect(user.rating).to eq(original_user_elo) #  Global user rating remains frozen
      end
    end

    context "when the submitted answer is PARTIALLY CORRECT (V2 Engine Check)" do
      it "returns a 200 OK status, updates user history as incorrect, and applies partial credit to Elo math" do
        partial_question = Question.create!(
          kind: :open_cloze,
          level: b2_level,
          main: "He had * * solving the advanced puzzle.",
          answers: [ "little difficulty || solving" ],
          rating: 2400
        )

        partial_question.tags << Tag.find_or_create_by!(name: "grammar")

        post "/api/v1/questions/#{partial_question.id}/submit_answer",
             params: { answer: "little difficulty by solving", mode: "competitive" },
             headers: headers

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        # ✅ VERIFICATION 1: Confirm the evaluation engine scored the string as exactly 0.5 partial credit
        expect(json["score"]).to eq(0.5)
        expect(json["fully_correct"]).to eq(false)

        # ✅ VERIFICATION 2: Confirm the history queue flagged the record for review since it wasn't 100% perfect
        history = user.user_histories.find_by(question_id: partial_question.id)
        expect(history.needs_review).to eq(true)
        expect(history.first_attempt_correct).to eq(false)
      end
    end
  end
end
