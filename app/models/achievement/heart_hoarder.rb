class Achievement::HeartHoarder < Achievement
  def self.achievement_type
    "heart_hoarder"
  end

  def self.achievement_name
    "Heart Hoarder"
  end

  def self.points
    150
  end

  def self.requirements_text
    "Collect 20 hearts in a single game"
  end

  def self.check_progress(game_session)
    game_session.hearts_collected.to_i >= 20
  end
end
