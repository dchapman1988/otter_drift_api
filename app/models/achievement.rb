class Achievement < ApplicationRecord
  has_many :earned_achievements, dependent: :destroy
  has_many :players, through: :earned_achievements

  validates :name, presence: true
  validates :points, numericality: { greater_than: 0 }

  # Override in subclasses
  def check_progress(game_session)
    raise NotImplementedError, "Subclasses must implement check_progress"
  end

  def requirements_text
    raise NotImplementedError, "Subclasses must implement requirements_text"
  end
end
