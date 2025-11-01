require 'rails_helper'

RSpec.describe EarnedAchievement, type: :model do
  describe 'factory' do
    it 'creates a valid earned_achievement' do
      earned_achievement = build(:earned_achievement)
      expect(earned_achievement).to be_valid
    end
  end

  describe 'associations' do
    it { should belong_to(:player) }
    it { should belong_to(:achievement) }
    it { should belong_to(:game_session).optional }
  end

  describe 'validations' do
    subject { create(:earned_achievement) }

    it { should validate_uniqueness_of(:player_id).scoped_to(:achievement_id) }

    it 'prevents duplicate achievements for the same player' do
      player = create(:player)
      achievement = create(:achievement)
      create(:earned_achievement, player: player, achievement: achievement)

      duplicate = build(:earned_achievement, player: player, achievement: achievement)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:player_id]).to include('has already been taken')
    end

    it 'allows the same achievement for different players' do
      achievement = create(:achievement)
      player1 = create(:player)
      player2 = create(:player)

      earned1 = create(:earned_achievement, player: player1, achievement: achievement)
      earned2 = build(:earned_achievement, player: player2, achievement: achievement)

      expect(earned2).to be_valid
    end

    it 'allows different achievements for the same player' do
      player = create(:player)
      achievement1 = create(:achievement)
      achievement2 = create(:achievement)

      earned1 = create(:earned_achievement, player: player, achievement: achievement1)
      earned2 = build(:earned_achievement, player: player, achievement: achievement2)

      expect(earned2).to be_valid
    end
  end

  describe 'callbacks' do
    describe '#set_earned_at' do
      it 'sets earned_at to current time when not provided' do
        earned_achievement = create(:earned_achievement, earned_at: nil)
        expect(earned_achievement.earned_at).to be_within(1.second).of(Time.current)
      end

      it 'does not override earned_at if already set' do
        custom_time = 2.days.ago
        earned_achievement = create(:earned_achievement, earned_at: custom_time)
        expect(earned_achievement.earned_at).to be_within(1.second).of(custom_time)
      end
    end
  end
end
