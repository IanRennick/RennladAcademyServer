namespace :api do
  namespace :v1 do
    # Register User API Route
    scope :users, module: :users do
      post "/", to: "registrations#create", as: :user_registration
    end

    # API Routes
    resources :writings
  end
end

scope :api do
  scope :v1 do
    use_doorkeeper do
      skip_controllers :authorizations, :applications, :authorized_applications
    end
  end
end
