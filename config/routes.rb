Rails.application.routes.draw do
  # View only rails pages
  root "pages#home"
  get "info", to: "pages#info"
  get "/u/:id", to: "users#profile", as: "user"

  # Rails Poutes
  resources :writings do
    resources :comments
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
