class Player < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :trackable,
         :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist

  has_many :game_sessions, dependent: :destroy
  has_many :earned_achievements, dependent: :destroy
  has_many :achievements, through: :earned_achievements
  has_one  :player_profile, dependent: :destroy

  validates :username, presence: true, uniqueness: { case_sensitive: false },
            length: { minimum: 3, maximum: 20 }
  validates :display_name, length: { maximum: 30 }, allow_blank: true
  validates :avatar_url, length: { maximum: 500 }, allow_blank: true

  # URL format validation for avatar_url (optional but recommended)
  validates :avatar_url, format: {
    with: URI::DEFAULT_PARSER.make_regexp(%w[http https]),
    message: "must be a valid URL"
  }, if: -> { avatar_url.present? }

  # Email uniqueness is already handled by Devise's :validatable module
  # But we can add case-insensitive uniqueness explicitly
  validates :email, uniqueness: { case_sensitive: false }

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
