class GameSession < ApplicationRecord
  has_many :high_scores, dependent: :destroy
end
