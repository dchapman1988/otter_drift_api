class GameSession < ApplicationRecord
  belongs_to :player, optional: true
  has_many :high_scores, dependent: :destroy
  has_many :earned_achievements, dependent: :destroy

  validates :session_id, presence: true, uniqueness: true
  validates :final_score, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :lilies_collected, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :obstacles_avoided, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  after_commit :record_high_score, on: [:create, :update]
  after_commit :update_player_stats, on: [:create, :update], if: :player_present_and_completed?
  after_commit :check_achievements, on: [:create, :update], if: :player_present_and_completed?

  scope :completed, -> { where.not(ended_at: nil, final_score: nil) }
  scope :for_player, ->(player) { where(player: player) }
  scope :guest_sessions, -> { where(player_id: nil) }

  def guest_session?
    player_id.nil?
  end

  def completed?
    ended_at.present? && final_score.present?
  end

  private

  def record_high_score
    CreateHighScoreJob.perform_later(id) if completed?
  end

  def update_player_stats
    UpdatePlayerStatsJob.perform_later(player_id, id)
  end

  def check_achievements
    CheckAchievementsJob.perform_later(player_id, id)
  end

  def player_present_and_completed?
    player_id.present? && completed?
  end
end
