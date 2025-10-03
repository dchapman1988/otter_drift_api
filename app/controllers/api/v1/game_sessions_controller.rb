module Api
  module V1
    class GameSessionsController < ApplicationController
      # POST /api/v1/game_sessions
      def create
        @game_session = GameSession.find_or_initialize_by(session_id: game_session_params[:session_id])
        @game_session.assign_attributes(game_session_params)

        if @game_session.save
          render json: @game_session, status: :created, location: api_v1_game_sessions_path
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
