class Player < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :trackable,
         :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist

  has_many :game_sessions, dependent: :destroy
  has_many :earned_achievements, dependent: :destroy
  has_many :achievements, through: :earned_achievements
  has_one  :player_profile, dependent: :destroy
  has_one_attached :avatar

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

  # Avatar validations
  validate :avatar_validation

  def avatar_validation
    return unless avatar.attached?

    # Check content type (basic check, can be spoofed)
    unless avatar.content_type.in?(%w[image/png image/jpg image/jpeg image/gif image/webp])
      errors.add(:avatar, "must be a PNG, JPG, JPEG, GIF, or WebP image")
      return
    end

    # Check file size
    if avatar.byte_size > 5.megabytes
      errors.add(:avatar, "must be less than 5MB")
      nil
    end
  end

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
