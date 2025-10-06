class GameSession < ApplicationRecord
  has_many :high_scores, dependent: :destroy

  after_commit :record_high_score

  private

  def record_high_score
    CreateHighScoreJob.perform_later(id)
  end
end
