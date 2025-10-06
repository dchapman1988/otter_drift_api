Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      # Client authentication
      post 'auth/login', to: 'auth#create'
      
      # Player authentication  
      devise_for :players, 
                 path: 'players',
                 skip: [:sessions, :registrations]
      
      # Custom devise controllers
      devise_scope :player do
        post 'players/sign_in', to: 'players/sessions#create'
        delete 'players/sign_out', to: 'players/sessions#destroy'
        post 'players', to: 'players/registrations#create'
      end
      
      # Game endpoints
      resources :game_sessions, only: [:create, :index]
      resources :achievements, only: [:index]
    end
  end
end
