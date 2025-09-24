class HighScore < ApplicationRecord
  # associations
  belongs_to :game_session

  # validations
  validates :score, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # data scopes
  scope :top, ->(n = 10) { order(score: :desc, created_at: :asc).limit(n) }

  # delegates
  delegate :player_name, to: :game_session
  delegate :final_score, to: :game_session
  def score = final_score
end
