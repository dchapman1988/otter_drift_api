module Api
  module V1
    module Players
      class StatsController < ::ApplicationController
        include JwtAuthentication

        before_action :authenticate_player!
        before_action :load_player, only: [ :show ]

        def show
          response = {
            player_stats: {
              total_score: @player.total_score,
              games_played: @player.games_played,
              personal_best: @player.personal_best
            }
          }

          render json: response
        end

        private

        def authenticate_player!
          unless current_player
            render json: {
              errors: [ "Unauthorized" ]
            }, status: :unauthorized
          end
        end

        def load_player
          @player = current_player
        end
      end
    end
  end
end
