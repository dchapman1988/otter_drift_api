class Player < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :trackable,
         :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist

  has_many :game_sessions, dependent: :destroy
  has_many :earned_achievements, dependent: :destroy
  has_many :achievements, through: :earned_achievements

  validates :username, presence: true, uniqueness: true,
            length: { minimum: 3, maximum: 20 }
  validates :display_name, length: { maximum: 30 }, allow_blank: true

  def display_name_or_username
    display_name.presence || username
  end

  def personal_best
    game_sessions.completed.maximum(:final_score) || 0
  end

  def achievement_count
    earned_achievements.count
  end
end
