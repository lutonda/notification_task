Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"

  # API routes for notifications
  namespace :api do
    # Authentication routes
    post 'authentication/login', to: 'authentication#login'
    get 'authentication/verify', to: 'authentication#verify'
    
    resources :notifications do
      member do
        patch :mark_read
      end
    end
  end

  # ActionCable mount point
  mount ActionCable.server => '/cable'
end