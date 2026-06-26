namespace :api do
  namespace :v1 do
    # Register User API Route
    scope :users, module: :users do
      post "/", to: "registrations#create", as: :user_registration
    end

    # Question routes
    get "/questions/random", to: "questions#random"
    get "/questions/multiple_choice", to: "questions#multiple_choice"
    get "/questions/open_cloze", to: "questions#open_cloze"
    get "/questions/sentence_cloze", to: "questions#sentence_cloze"
    get "/questions/word_formation", to: "questions#word_formation"
  end
end

scope :api do
  scope :v1 do
    use_doorkeeper do
      skip_controllers :authorizations, :applications, :authorized_applications
      # Map BOTH creation and revocation to custom controller
      controllers tokens: "custom_tokens", token_revocations: "custom_tokens"
    end
  end
end
