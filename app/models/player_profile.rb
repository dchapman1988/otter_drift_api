class PlayerProfile < ApplicationRecord
  belongs_to :player

  # Validations
  validates :bio, length: { maximum: 500 }, allow_blank: true
  validates :favorite_otter_fact, length: { maximum: 500 }, allow_blank: true
  validates :title, length: { maximum: 50 }, allow_blank: true
  validates :profile_banner_url, length: { maximum: 500 }, allow_blank: true
  validates :location, length: { maximum: 100 }, allow_blank: true

  # URL format validation (optional but recommended)
  validates :profile_banner_url, format: {
    with: URI::DEFAULT_PARSER.make_regexp(%w[http https]),
    message: "must be a valid URL"
  }, if: -> { profile_banner_url.present? }
end
