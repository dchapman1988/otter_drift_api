Rails.application.routes.draw do
  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"
  # Player authentication - custom controllers
  devise_for :players,
             path: "players",
             controllers: {
               sessions: "players/sessions",
               registrations: "players/registrations"
             }


  namespace :api do
    namespace :v1 do
      # Client authentication
      post "auth/login", to: "auth#create"

      # Player profile management and stats
      namespace :players do
        resource :profile, only: [ :update, :show ]
        resource :stats, only: [ :show ]
        get ":username/achievements", to: "achievements#index", as: :achievements
        get ":username/game-history", to: "game_histories#index", as: :game_history
      end

      # Game endpoints
      resources :game_sessions, only: [ :create, :index ]
      resources :achievements, only: [ :index ]

      # Leaderboards
      get "leaderboard", to: "leaderboards#index"
    end
  end
end
