# config/routes.rb
# =========================================================================
# SYSTEM authoritative GLOBAL ROUTING REGISTRY
# - Handles standard web views, administrative dashboards, and membership paths
# - Integrates Devise authentication filters and handles custom profile sub-paths
# - Delegates versioned API micro-routing splits cleanly to the draw engine
# =========================================================================
Rails.application.routes.draw do
  # --- Standard Web Application Views Pages ---
  root "pages#home"
  get "info", to: "pages#info"

  # Clean, short student profile and interactive chat workspace paths
  get "/u/:id",      to: "users#profile", as: "user"
  get "/u/:id/chat", to: "users#chat",    as: "user_chat"

  get "search", to: "search#index"


  # --- Administrative Control Panel Board ---
  get "/admin/dashboard", to: "dashboard#index", as: :admin_dashboard

  # --- Polymorphic Discussion Forum Resources ---
  resources :writings do
    resources :comments, only: [ :create, :update, :destroy ]
  end

  resources :questions, only: [ :index, :show ] do
    resources :comments, only: [ :create, :update, :destroy ]
  end

  # --- Real-Time Communications Rooms Suite ---
  resources :rooms do
    resources :messages, only: [ :create ]
  end

  # --- Navbar Async Alerts System ---
  resources :notifications, only: [] do
    collection do
      post :mark_all_as_read
    end
    member do
      post :toggle_read
    end
  end

  # --- Devise Authentication Views Sessions Controllers ---
  devise_for :users, controllers: {
    sessions: "users/sessions",
    registrations: "users/registrations"
  }

  # --- Modular Micro-Routing Extension Splits ---
  # Automatically draws the isolated stateless API endpoints from config/routes/api.rb
  # ✅ NOTE: Your custom use_doorkeeper cookie configuration block lives securely inside that file!
  draw :api

  # --- Platform System Health & Telemetry ---
  # Exposes an active checkpoint for load-balancers and uptime monitors
  get "up" => "rails/health#show", as: :rails_health_check
end
