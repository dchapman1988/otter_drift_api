require 'rails_helper'

RSpec.describe AchievementChecker do
  let(:player) { create(:player) }
  let(:lily_collector) { create(:lily_collector) }
  let(:heart_hoarder) { create(:heart_hoarder) }

  describe '.check_and_award' do
    context 'when player meets achievement criteria' do
      let(:game_session) do
        create(:game_session,
               player: player,
               lilies_collected: 15,
               hearts_collected: 25)
      end

      before do
        lily_collector
        heart_hoarder
      end

      it 'creates EarnedAchievement records' do
        expect {
          described_class.check_and_award(player, game_session)
        }.to change(EarnedAchievement, :count).by(2)
      end

      it 'links achievements to the game session' do
        described_class.check_and_award(player, game_session)

        earned = player.earned_achievements.last
        expect(earned.game_session).to eq(game_session)
      end

      it 'returns newly earned achievements' do
        newly_earned = described_class.check_and_award(player, game_session)

        expect(newly_earned).to include(lily_collector, heart_hoarder)
      end
    end

    context 'when player does not meet criteria' do
      let(:game_session) do
        create(:game_session,
               player: player,
               lilies_collected: 5,
               hearts_collected: 10)
      end

      before do
        lily_collector
        heart_hoarder
      end

      it 'does not create EarnedAchievement records' do
        expect {
          described_class.check_and_award(player, game_session)
        }.not_to change(EarnedAchievement, :count)
      end

      it 'returns empty array' do
        newly_earned = described_class.check_and_award(player, game_session)
        expect(newly_earned).to be_empty
      end
    end

    context 'when player already earned the achievement' do
      let(:game_session) do
        create(:game_session, player: player, lilies_collected: 15)
      end

      before do
        lily_collector
        create(:earned_achievement, player: player, achievement: lily_collector)
      end

      it 'does not award achievement twice' do
        expect {
          described_class.check_and_award(player, game_session)
        }.not_to change(EarnedAchievement, :count)
      end
    end
  end
end
