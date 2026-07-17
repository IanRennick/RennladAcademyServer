require 'rails_helper'

RSpec.describe "Admin Search Interface", type: :request do
  include Devise::Test::IntegrationHelpers

  # ✅ FIX 1: Create a master admin account to bypass your global gatekeeper shield!
  let!(:admin_user) do
    User.create!(
      username: "search_admin_tester",
      email: "admin_search@test.com",
      password: "password123",
      role: :admin
    )
  end

  # ✅ FIX 2: Automatically sign in the admin before every single request runs!
  before do
    sign_in admin_user
  end

  # 1. SETUP CLUSTER BASES: Establish levels, matching questions, and a tag
  let!(:b2_level) { Level.find_or_create_by!(name: "B2") { |l| l.initial_rating = 1200 } }
  let!(:c1_level) { Level.find_or_create_by!(name: "C1") { |l| l.initial_rating = 1500 } }

  let!(:phrasal_question) do
    Question.create!(
      kind: :multiple_choice,
      subtype: :mc_phrasal,
      level: b2_level,
      main: "Bob decided to * up a new sport.",
      options: [ "give", "take", "look" ],
      answers: [ "take" ],
      tag_list: "vocabulary, phrasal_verbs"
    )
  end

  let!(:conditional_question) do
    Question.create!(
      kind: :sentence_cloze,
      subtype: :sc_conditional,
      level: c1_level,
      main: "If I * more time, I would fly.",
      prompt: "HAVE",
      keyword: "unreal conditional",
      options: [],
      answers: [ "had" ],
      tag_list: "grammar"
    )
  end

  describe "GET /search" do
    context "when searching for specific keywords or sentence content" do
      it "successfully filters down to questions matching the text box parameter" do
        get "/search", params: { q: { main_or_prompt_or_keyword_or_options_as_text_or_answers_as_text_or_tags_name_i_cont_any: "sport" } }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Bob decided to * up a new sport.")
        expect(response.body).to_not include("If I * more time")
      end
    end

    context "when searching across nested JSON array items" do
      it "safely searches inside options and answers arrays using cast conversion rules" do
        get "/search", params: { q: { main_or_prompt_or_keyword_or_options_as_text_or_answers_as_text_or_tags_name_i_cont_any: "look" } }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Bob decided to * up a new sport.")
        expect(response.body).to_not include("If I * more time")
      end
    end

    context "when searching by relational tag names" do
      it "automatically inner joins the tags table and matches tag strings dynamically" do
        get "/search", params: { q: { main_or_prompt_or_keyword_or_options_as_text_or_answers_as_text_or_tags_name_i_cont_any: "grammar" } }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("If I * more time, I would fly.")
        expect(response.body).to_not include("Bob decided to * up a new sport.")
      end
    end

    context "when utilizing Ransack table header sort options" do
      it "renders the results using proper sorting variables" do
        get "/search", params: { q: { s: "rating desc" } }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("unreal conditional").or(include("had"))
      end
    end

   context "when performing an OMNI-SEARCH for student profiles" do
      it "returns matching user records at the top of the payload template view" do
        # ✅ FIX: Removed the "test_student =" variable hook completely to silence unused variable warnings!
        User.create!(
          username: "omni_student_tester",
          email: "omni_tester@example.com",
          password: "password123",
          password_confirmation: "password123",
          role: :admin
        )

        # Execute search for the username we just generated
        get "/search", params: { q: { main_or_prompt_or_keyword_or_options_as_text_or_answers_as_text_or_tags_name_i_cont_any: "omni_student_tester" } }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("omni_student_tester")
        expect(response.body).to include("omni_tester@example.com")

        # Verify filtering cleans up unmatched student rows
        get "/search", params: { q: { main_or_prompt_or_keyword_or_options_as_text_or_answers_as_text_or_tags_name_i_cont_any: "completely_empty_unmatched_search_term" } }
        expect(response.body).to_not include("omni_tester@example.com")
      end
    end
  end
end
