class UpdatePlayerStatsJob < ApplicationJob
  queue_as :default

  def perform(player_id, game_session_id)
    player = Player.find(player_id)
    game_session = GameSession.find(game_session_id)

    return unless game_session.completed?

    Rails.logger.info "UPDATING PLAYER STATS!"
    player.with_lock do
      player.total_score += game_session.final_score
      player.games_played += 1
      player.last_played_at = game_session.ended_at
      player.save!
    end
    Rails.logger.info "FINISHED UPDATING PLAYER STATS: #{player.inspect}"
  end
end
