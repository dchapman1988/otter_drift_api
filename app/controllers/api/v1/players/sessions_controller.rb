module Api
  module V1
    module Players
      class SessionsController < Devise::SessionsController
        respond_to :json
        skip_before_action :authenticate_request

        private

        def respond_with(resource, _opts = {})
          render json: {
            player: {
              id: resource.id,
              email: resource.email,
              username: resource.username,
              display_name: resource.display_name_or_username,
              total_score: resource.total_score,
              games_played: resource.games_played
            }
          }, status: :ok
        end

        def respond_to_on_destroy
          if current_player
            render json: { message: 'Logged out successfully' }, status: :ok
          else
            render json: { errors: ['Not logged in'] }, status: :unauthorized
          end
        end
      end
    end
  end
end
