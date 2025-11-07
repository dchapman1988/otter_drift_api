module Api
  module V1
    class GameSessionsController < ApplicationController
      # GET /api/v1/game_sessions
      def index
        unless Current.player
          return render json: { error: "Authentication required" }, status: :unauthorized
        end

        @game_sessions = Current.player.game_sessions
                                       .order(created_at: :desc)
                                       .limit(50)

        # Return as array, not wrapped in object
        render json: @game_sessions.as_json(
          except: [ :updated_at ],
          methods: [ :guest_session? ]
        )
      end

      # POST /api/v1/game_sessions
      def create
        @game_session = GameSession.find_or_initialize_by(session_id: game_session_params[:session_id])

        # Link to player if authenticated
        @game_session.player = Current.player if Current.player

        # Log client ID for analytics (when using client authentication)
        Rails.logger.info "Game session created by client: #{current_client_id}" if current_client_id

        @game_session.assign_attributes(game_session_params)

        if @game_session.save
          response_data = game_session_response(@game_session)
          render json: response_data, status: :created
        else
          render json: { errors: @game_session.errors.full_messages },
                 status: :unprocessable_content
        end
      end

      private

      def game_session_params
        params.require(:game_session).permit(
          :session_id,
          :player_name,
          :seed,
          :started_at,
          :ended_at,
          :final_score,
          :game_duration,
          :max_speed_reached,
          :obstacles_avoided,
          :lilies_collected,
          :hearts_collected
        )
      end

      def game_session_response(game_session)
        response = {
          game_session: game_session.as_json(
            except: [ :updated_at ],
            methods: [ :guest_session? ]
          )
        }

        # Include newly earned achievements if player is authenticated
        if Current.player && game_session.completed?
          response[:player_stats] = {
            total_score: Current.player.total_score,
            games_played: Current.player.games_played,
            personal_best: Current.player.personal_best
          }
        end

        response
      end
    end
  end
end
