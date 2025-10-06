class Achievement::LilyCollector < Achievement
  def check_progress(game_session)
    game_session.lilies_collected.to_i >= 10
  end
  
  def requirements_text
    "Collect 10 lilies in a single game"
  end
end

