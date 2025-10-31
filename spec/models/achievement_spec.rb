require 'rails_helper'

RSpec.describe Achievement, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:earned_achievements).dependent(:destroy) }
    it { is_expected.to have_many(:players).through(:earned_achievements) }
  end

  describe 'validations' do
    subject { build(:achievement) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:achievement_type) }
    it { is_expected.to validate_numericality_of(:points).is_greater_than(0) }
  end

  describe '.templates' do
    it 'returns all achievement template classes' do
      templates = Achievement.templates

      expect(templates).to include(Achievement::LilyCollector)
      expect(templates).to include(Achievement::HeartHoarder)
      expect(templates.size).to eq(2)
    end
  end

  describe '.unearned_templates_for' do
    let(:player) { create(:player) }

    context 'when player has not earned any achievements' do
      it 'returns all templates' do
        templates = Achievement.unearned_templates_for(player)

        expect(templates).to include(Achievement::LilyCollector)
        expect(templates).to include(Achievement::HeartHoarder)
        expect(templates.size).to eq(2)
      end
    end

    context 'when player has earned some achievements' do
      before do
        lily_achievement = Achievement.from_template(Achievement::LilyCollector)
        create(:earned_achievement, player: player, achievement: lily_achievement)
      end

      it 'returns only unearned templates' do
        templates = Achievement.unearned_templates_for(player)

        expect(templates).to include(Achievement::HeartHoarder)
        expect(templates).not_to include(Achievement::LilyCollector)
        expect(templates.size).to eq(1)
      end
    end

    context 'when player has earned all achievements' do
      before do
        Achievement.templates.each do |template|
          achievement = Achievement.from_template(template)
          create(:earned_achievement, player: player, achievement: achievement)
        end
      end

      it 'returns empty array' do
        templates = Achievement.unearned_templates_for(player)
        expect(templates).to be_empty
      end
    end
  end

  describe '.from_template' do
    let(:template_class) { Achievement::LilyCollector }

    context 'when achievement record does not exist' do
      it 'creates a new achievement record' do
        expect {
          Achievement.from_template(template_class)
        }.to change(Achievement, :count).by(1)
      end

      it 'sets attributes from template' do
        achievement = Achievement.from_template(template_class)

        expect(achievement.achievement_type).to eq('lily_collector')
        expect(achievement.name).to eq('Lily Collector')
        expect(achievement.description).to eq('Collect 10 lilies in a single game')
        expect(achievement.points).to eq(100)
      end

      it 'persists the record' do
        achievement = Achievement.from_template(template_class)
        expect(achievement).to be_persisted
      end
    end

    context 'when achievement record already exists' do
      let!(:existing_achievement) { create(:lily_collector_achievement) }

      it 'does not create a new record' do
        expect {
          Achievement.from_template(template_class)
        }.not_to change(Achievement, :count)
      end

      it 'returns the existing record' do
        achievement = Achievement.from_template(template_class)
        expect(achievement.id).to eq(existing_achievement.id)
      end
    end
  end

  describe 'class method requirements' do
    it 'raises NotImplementedError for achievement_type' do
      expect {
        Achievement.achievement_type
      }.to raise_error(NotImplementedError, "Subclasses must implement achievement_type")
    end

    it 'raises NotImplementedError for achievement_name' do
      expect {
        Achievement.achievement_name
      }.to raise_error(NotImplementedError, "Subclasses must implement achievement_name")
    end

    it 'raises NotImplementedError for points' do
      expect {
        Achievement.points
      }.to raise_error(NotImplementedError, "Subclasses must implement points")
    end

    it 'raises NotImplementedError for requirements_text' do
      expect {
        Achievement.requirements_text
      }.to raise_error(NotImplementedError, "Subclasses must implement requirements_text")
    end

    it 'raises NotImplementedError for check_progress' do
      game_session = build(:game_session)
      expect {
        Achievement.check_progress(game_session)
      }.to raise_error(NotImplementedError, "Subclasses must implement check_progress")
    end
  end
end
