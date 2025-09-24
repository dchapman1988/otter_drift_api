module Api
  module V1
    class GameSessionsController < ApplicationController
      # POST /game_sessions
      def create
        @game_session = GameSession.new(game_session_params)

        if @game_session.save
          render json: @game_session, status: :created, location: @game_session
        else
          render json: @game_session.errors, status: :unprocessable_content
        end
      end

      private

      # Only allow a list of trusted parameters through.
      def game_session_params
        params.expect(game_session: [ :session_id, :player_name, :seed, :started_at, :ended_at, :final_score, :game_duration, :max_speed_reached, :obstacles_avoided, :lilies_collected ])
      end
    end
  end
end
