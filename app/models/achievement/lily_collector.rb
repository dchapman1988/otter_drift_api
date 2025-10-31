class Achievement::LilyCollector < Achievement
  def self.achievement_type
    "lily_collector"
  end

  def self.achievement_name
    "Lily Collector"
  end

  def self.points
    100
  end

  def self.requirements_text
    "Collect 10 lilies in a single game"
  end

  def self.check_progress(game_session)
    game_session.lilies_collected.to_i >= 10
  end
end
