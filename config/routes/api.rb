namespace :api do
  namespace :v1 do
    # Register User API Route
    scope :users, module: :users do
      post "/", to: "registrations#create", as: :user_registration
    end

    resources :questions, only: [ :show ] do
      collection do
        get :random
        get :review_queue
      end
      member do
        post :submit_answer # POST /api/v1/questions/:id/submit_answer
      end
    end

    resource :stats, only: [ :show ]
    resources :comments, only: [ :create, :update, :destroy ]
  end
end

scope :api do
  scope :v1 do
    use_doorkeeper do
      skip_controllers :authorizations, :applications, :authorized_applications
      # Map creation and revocation to dedicated custom controllers
      controllers tokens: "custom_tokens", token_revocations: "custom_token_revocations"
    end
  end
end
