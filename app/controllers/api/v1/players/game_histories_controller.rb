module Api
  module V1
    module Players
      class GameHistoriesController < ApplicationController
        def index
          player = Player.find_by(username: params[:username])

          unless player
            render json: { errors: ["Player not found"] }, status: :not_found
            return
          end

          limit = parse_limit(params[:limit])
          offset = params[:offset].to_i || 0

          game_sessions = player.game_sessions
                               .completed
                               .includes(:high_scores)
                               .select('game_sessions.*, COUNT(earned_achievements.id)::integer as achievements_count')
                               .left_joins(:earned_achievements)
                               .group('game_sessions.id')
                               .order(ended_at: :desc)
                               .limit(limit)
                               .offset(offset)
                               .to_a # Load the results

          total_count = player.game_sessions.completed.count

          render json: {
            player: {
              username: player.username,
              total_games: total_count
            },
            game_history: game_sessions.map { |session| format_game_session(session) },
            pagination: {
              limit: limit,
              offset: offset,
              total: total_count,
              returned: game_sessions.length
            }
          }
        end

        private

        def parse_limit(limit_param)
          limit = limit_param.to_i
          return 20 if limit <= 0
          [limit, 100].min # Max 100 games per request
        end

        def format_game_session(session)
          {
            session_id: session.session_id,
            final_score: session.final_score,
            seed: session.seed,
            started_at: session.started_at,
            ended_at: session.ended_at,
            game_duration: session.game_duration,
            stats: {
              lilies_collected: session.lilies_collected,
              obstacles_avoided: session.obstacles_avoided,
              hearts_collected: session.hearts_collected,
              max_speed_reached: session.max_speed_reached
            },
            high_scores: session.high_scores.map do |score|
              {
                id: score.id,
                score: score.score,
                player_name: score.player_name,
                created_at: score.created_at
              }
            end,
            achievements_earned: session.achievements_count.to_i
          }
        end
      end
    end
  end
end
