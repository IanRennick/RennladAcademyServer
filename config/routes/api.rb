# config/routes/api.rb
# =========================================================================
# SYSTEM ISOLATED STATELESS API MICRO-ROUTING EXTENSION REGISTER
# - Houses all versioned, stateless JSON endpoints for external integration
# - Groups business actions and token generation structures under a unified namespace
# - Maps OAuth client creation and revocation routes to specialized controllers
# =========================================================================
namespace :api, defaults: { format: :json } do
  namespace :v1 do
    # --- 1. USER ENROLLMENT & IDENTITY MANAGEMENT ---
    scope :users, module: :users do
      post "/", to: "registrations#create", as: :user_registration
    end

    # --- 2. OAUTH SECURITY GATEWAY CHECKPOINTS ---
    # Unified directly inside the core versioned namespace to optimize client routes
    use_doorkeeper do
      skip_controllers :authorizations, :applications, :authorized_applications
      controllers tokens: "custom_tokens", token_revocations: "custom_token_revocations"
    end

    # --- 3. CURRICULUM QUESTIONS POOL ENDPOINTS ---
    resources :questions, only: [ :show ] do
      collection do
        get :random
        get :review_queue
      end
      member do
        post :submit_answer # POST /api/v1/questions/:id/submit_answer
      end
    end

    # --- 4. MULTI-DIMENSIONAL PERFORMANCE TELEMETRY ---
    resource :stats, only: [ :show ]

    # --- 5. POLYMORPHIC DISCUSSION FORUM COMMUNICATIONS ---
    resources :comments, only: [ :create, :update, :destroy ]

    # --- 6. STATELESS NOTIFICATIONS ALERTS CONTROL (NEW) ---
    resources :notifications, only: [ :index, :update ] do
      collection do
        post :mark_all_as_read
      end
    end

    # --- 7. CROWDSOURCED BUG & TYPO REPORTING GATEWAY (NEW) ---
    resources :reports, only: [ :create ]

    # --- 8. EXAMS POOLS & SUBMISSIONS GATEWAYS (NEW V3) ---
    resources :prompts, only: [ :index, :show ]
    resources :submissions, only: [ :index, :show, :create, :update ]
  end
end
