module Api
  module V1
    module Players
      class AchievementsController < ::ApplicationController
        before_action :load_player

        # Map achievement types to emoji fallbacks
        ACHIEVEMENT_EMOJIS = {
          "lily_collector" => "🌸",
          "heart_hoarder" => "💖",
          "speed_demon" => "⚡",
          "obstacle_master" => "🎯",
          "marathon_runner" => "🏃",
          "perfect_score" => "🏆",
          "first_game" => "🎮",
          "veteran" => "⭐",
          "high_scorer" => "💎",
          "collector" => "🎁"
        }.freeze

        DEFAULT_EMOJI = "🏅"

        def index
          earned_achievements = @player.earned_achievements
            .includes(:achievement)
            .order(earned_at: :desc)

          achievements_data = earned_achievements.map do |earned|
            achievement = earned.achievement
            {
              name: achievement.name,
              description: achievement.description,
              achievement_type: achievement.achievement_type,
              points: achievement.points,
              badge_url: badge_url_or_emoji(achievement),
              collected_at: earned.earned_at
            }
          end

          render json: {
            username: @player.username,
            total_achievements: achievements_data.count,
            achievements: achievements_data
          }
        end

        private

        def load_player
          @player = Player.find_by!(username: params[:username])
        rescue ActiveRecord::RecordNotFound
          render json: {
            errors: [ "Player not found" ]
          }, status: :not_found
        end

        def badge_url_or_emoji(achievement)
          # If icon_url is present and not blank, use it as badge_url
          if achievement.icon_url.present?
            achievement.icon_url
          else
            # Otherwise, return the appropriate emoji based on achievement type
            emoji_for_achievement(achievement.achievement_type)
          end
        end

        def emoji_for_achievement(achievement_type)
          # Convert achievement type to snake_case key if needed
          normalized_type = achievement_type.to_s.underscore
          ACHIEVEMENT_EMOJIS.fetch(normalized_type, DEFAULT_EMOJI)
        end
      end
    end
  end
end
