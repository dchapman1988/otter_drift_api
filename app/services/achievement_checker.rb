class AchievementChecker
  def self.check_and_award(player, game_session)
    new(player, game_session).check_and_award
  end

  def initialize(player, game_session)
    @player = player
    @game_session = game_session
  end

  def check_and_award
    newly_earned = []

    unearned_achievements.find_each do |achievement|
      if achievement.check_progress(@game_session)
        earned = EarnedAchievement.create!(
          player: @player,
          achievement: achievement,
          game_session: @game_session
        )
        newly_earned << achievement

        Rails.logger.info "Player #{@player.username} earned achievement: #{achievement.name}"
      end
    end

    newly_earned
  end

  private

  def unearned_achievements
    Achievement.where.not(
      id: @player.earned_achievements.select(:achievement_id)
    )
  end
end
