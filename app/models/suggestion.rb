class Suggestion < ApplicationRecord
  belongs_to :player, optional: true

  validates :note, presence: true, length: { minimum: 3, maximum: 1000 }

  def to_s
    note.presence || super
  end
end
