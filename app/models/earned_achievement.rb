class EarnedAchievement < ApplicationRecord
  belongs_to :player
  belongs_to :achievement
  belongs_to :game_session, optional: true

  validates :player_id, uniqueness: { scope: :achievement_id }

  before_create :set_earned_at

  private

  def set_earned_at
    self.earned_at ||= Time.current
  end
end
