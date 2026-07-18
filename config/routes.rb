Rails.application.routes.draw do
  # View only rails pages
  root "pages#home"
  get "info", to: "pages#info"
  get "/u/:id", to: "users#profile", as: "user"
  get "/u/:id/chat", to: "users#chat", as: "user_chat"
  get "search", to: "search#index"
  get "multiple_choices", to: "questions#multiple_choices"
  get "open_clozes", to: "questions#open_clozes"
  get "word_formations", to: "questions#word_formations"
  get "sentence_clozes", to: "questions#sentence_clozes"

  get "/admin/dashboard", to: "dashboard#index", as: :admin_dashboard

  # Admin Pages
  get "admin", to: "admin#index"
  get "admin/users"
  get "admin/writings"
  get "admin/show_writing/:id", to: "admin#show_writing", as: "admin_writing"

  # Rails Poutes
  resources :writings do
    resources :comments
  end

  resources :questions, only: [ :index, :show ] do
    resources :comments
  end


  resources :rooms do
    resources :messages
  end

  resources :notifications, only: [] do
    collection do
      post :mark_all_as_read
    end
    member do
      post :toggle_read
    end
  end

  # Devise user pages
  devise_for :users, controllers: {
    sessions: "users/sessions",
    registrations: "users/registrations"
  }

  # Draw API routes
  draw :api

  # Set up Doorkeeper for API auth
  use_doorkeeper

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
