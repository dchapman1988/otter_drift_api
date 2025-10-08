Rails.application.routes.draw do
  # Player authentication - custom controllers
  devise_for :players, 
    path: 'players',
    controllers: {
      sessions: 'players/sessions',
      registrations: 'players/registrations'
    }

  # Player profile management
  namespace :players do
    resource :profile, only: [:update]
  end

  namespace :api do
    namespace :v1 do
      # Client authentication
      post 'auth/login', to: 'auth#create'
      
      
      # Custom devise controllers
      
      # Game endpoints
      resources :game_sessions, only: [:create, :index]
      resources :achievements, only: [:index]
    end
  end
end
