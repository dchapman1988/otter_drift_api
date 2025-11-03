module Api
  module V1
    class LeaderboardsController < ::ApplicationController
      DEFAULT_LIMIT = 100
      MAX_LIMIT = 500

      def index
        limit = parse_limit(params[:limit])

        high_scores = HighScore
          .includes(game_session: :player)
          .top(limit)

        leaderboard_data = high_scores.each_with_index.map do |high_score, index|
          game_session = high_score.game_session
          player = game_session.player

          entry = {
            rank: index + 1,
            score: high_score.score,
            player_name: player_display_name(game_session, player),
            achieved_at: high_score.created_at,
            is_guest: game_session.guest_session?
          }

          # Add player details if authenticated player
          if player.present?
            entry[:player] = {
              username: player.username,
              avatar_url: player.avatar_url
            }
          end

          entry
        end

        render json: {
          leaderboard: leaderboard_data,
          total_entries: leaderboard_data.count,
          limit: limit
        }
      end

      private

      def parse_limit(limit_param)
        return DEFAULT_LIMIT if limit_param.blank?

        limit = limit_param.to_i
        return DEFAULT_LIMIT if limit <= 0

        [ limit, MAX_LIMIT ].min
      end

      def player_display_name(game_session, player)
        if player.present?
          player.display_name_or_username
        elsif game_session.player_name.present?
          game_session.player_name
        else
          "Guest Player"
        end
      end
    end
  end
end
