class Achievement::HeartHoarder < Achievement
  def check_progress(game_session)
    game_session.hearts_collected.to_i >= 20
  end
  
  def requirements_text
    "Collect 20 hearts in a single game"
  end
end

