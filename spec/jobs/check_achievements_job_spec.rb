require 'rails_helper'

RSpec.describe CheckAchievementsJob, type: :job do
  let(:player) { create(:player) }
  let(:game_session) do
    create(:game_session,
           player: player,
           lilies_collected: 15,
           hearts_collected: 25,
           ended_at: Time.current,
           final_score: 1000)
  end

  describe '#perform' do
    it 'finds the player' do
      expect(Player).to receive(:find).with(player.id).and_return(player)
      allow(GameSession).to receive(:find).and_return(game_session)
      allow(AchievementChecker).to receive(:check_and_award)

      described_class.perform_now(player.id, game_session.id)
    end

    it 'finds the game session' do
      allow(Player).to receive(:find).and_return(player)
      expect(GameSession).to receive(:find).with(game_session.id).and_return(game_session)
      allow(AchievementChecker).to receive(:check_and_award)

      described_class.perform_now(player.id, game_session.id)
    end

    it 'calls AchievementChecker.check_and_award with player and game session' do
      expect(AchievementChecker).to receive(:check_and_award).with(player, game_session)

      described_class.perform_now(player.id, game_session.id)
    end

    it 'creates earned achievements when criteria are met' do
      expect {
        described_class.perform_now(player.id, game_session.id)
      }.to change(EarnedAchievement, :count).by(2)
    end

    context 'when player is not found' do
      it 'raises ActiveRecord::RecordNotFound' do
        expect {
          described_class.perform_now(999999, game_session.id)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when game session is not found' do
      it 'raises ActiveRecord::RecordNotFound' do
        expect {
          described_class.perform_now(player.id, 999999)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when player does not meet any achievement criteria' do
      let(:low_score_session) do
        create(:game_session,
               player: player,
               lilies_collected: 5,
               hearts_collected: 10,
               ended_at: Time.current,
               final_score: 100)
      end

      it 'does not create any earned achievements' do
        expect {
          described_class.perform_now(player.id, low_score_session.id)
        }.not_to change(EarnedAchievement, :count)
      end
    end

    context 'when player already earned some achievements' do
      let(:game_session2) do
        create(:game_session,
               player: player,
               lilies_collected: 15,
               hearts_collected: 25,
               ended_at: Time.current,
               final_score: 1000)
      end

      before do
        # First session awards achievements
        described_class.perform_now(player.id, game_session.id)
      end

      it 'does not award the same achievements again' do
        expect {
          described_class.perform_now(player.id, game_session2.id)
        }.not_to change(EarnedAchievement, :count)
      end
    end
  end
end
