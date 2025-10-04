class GameSession < ApplicationRecord
  has_many :high_scores, dependent: :destroy

  after_commit :record_high_score

  private

  def record_high_score
    high_scores.find_or_create_by(score: final_score)
  end
end
