require 'rails_helper'

RSpec.describe UpdatePlayerStatsJob, type: :job do
  let(:player) { create(:player, total_score: 1000, games_played: 5) }
  let(:game_session) do
    create(:game_session,
           player: player,
           final_score: 500,
           ended_at: Time.current)
  end

  describe '#perform' do
    it 'updates player total_score' do
      expect {
        described_class.perform_now(player.id, game_session.id)
        player.reload
      }.to change(player, :total_score).from(1000).to(1500)
    end

    it 'increments games_played' do
      expect {
        described_class.perform_now(player.id, game_session.id)
        player.reload
      }.to change(player, :games_played).from(5).to(6)
    end

    it 'updates last_played_at' do
      described_class.perform_now(player.id, game_session.id)
      player.reload

      expect(player.last_played_at).to be_within(1.second).of(game_session.ended_at)
    end

    it 'uses database locking' do
      expect_any_instance_of(Player).to receive(:with_lock).and_call_original
      described_class.perform_now(player.id, game_session.id)
    end

    context 'when game session is incomplete' do
      let(:incomplete_session) do
        create(:game_session, player: player, ended_at: nil, final_score: nil)
      end

      it 'does not update player stats' do
        expect {
          described_class.perform_now(player.id, incomplete_session.id)
          player.reload
        }.not_to change(player, :total_score)
      end
    end
  end
end
