class Achievement < ApplicationRecord
  has_many :earned_achievements, dependent: :destroy
  has_many :players, through: :earned_achievements

  validates :name, presence: true
  validates :achievement_type, presence: true, uniqueness: true
  validates :points, numericality: { greater_than: 0 }

  # Registry of all achievement template classes
  def self.templates
    [
      Achievement::LilyCollector,
      Achievement::HeartHoarder
    ]
  end

  # Get templates that a player hasn't earned yet
  def self.unearned_templates_for(player)
    earned_types = player.earned_achievements.joins(:achievement).pluck(:achievement_type)
    templates.reject { |template| earned_types.include?(template.achievement_type) }
  end

  # Find or create Achievement record from template class
  def self.from_template(template_class)
    find_or_create_by!(achievement_type: template_class.achievement_type) do |achievement|
      achievement.name = template_class.achievement_name
      achievement.description = template_class.requirements_text
      achievement.points = template_class.points
    end
  end

  # Class methods that subclasses must implement
  def self.achievement_type
    raise NotImplementedError, "Subclasses must implement achievement_type"
  end

  def self.achievement_name
    raise NotImplementedError, "Subclasses must implement achievement_name"
  end

  def self.points
    raise NotImplementedError, "Subclasses must implement points"
  end

  def self.requirements_text
    raise NotImplementedError, "Subclasses must implement requirements_text"
  end

  def self.check_progress(game_session)
    raise NotImplementedError, "Subclasses must implement check_progress"
  end
end
