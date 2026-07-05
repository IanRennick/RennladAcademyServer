namespace :api do
  namespace :v1 do
    # Register User API Route
    scope :users, module: :users do
      post "/", to: "registrations#create", as: :user_registration
    end

    resources :questions, only: [ :show ] do
      collection do
        get :random
      end
      member do
        post :submit_answer # POST /api/v1/questions/:id/submit_answer
      end
    end

    resource :stats, only: [ :show ]
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
