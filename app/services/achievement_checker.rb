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

    # Iterate over unearned achievement template classes (LSP pattern)
    unearned_templates.each do |template_class|
      if template_class.check_progress(@game_session)
        # Find or create the Achievement record from the template
        achievement = Achievement.from_template(template_class)

        # Award it to the player
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

  def unearned_templates
    # Get template classes that the player hasn't earned yet
    Achievement.unearned_templates_for(@player)
  end
end
