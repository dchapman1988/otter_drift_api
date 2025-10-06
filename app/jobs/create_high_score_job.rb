class CreateHighScoreJob < ApplicationJob
  queue_as :default

  def perform(game_session_id)
    game_session = GameSession.find(game_session_id)
    game_session.high_scores.find_or_create_by(score: game_session.final_score)
  end
end
