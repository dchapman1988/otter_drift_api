class CheckAchievementsJob < ApplicationJob
  queue_as :default

  def perform(player_id, game_session_id)
    player = Player.find(player_id)
    game_session = GameSession.find(game_session_id)
    
    AchievementChecker.check_and_award(player, game_session)
  end
end
