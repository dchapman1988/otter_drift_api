require 'rails_helper'

RSpec.describe Achievement::LilyCollector do
  describe '.achievement_type' do
    it 'returns the achievement type identifier' do
      expect(described_class.achievement_type).to eq('lily_collector')
    end
  end

  describe '.achievement_name' do
    it 'returns the achievement name' do
      expect(described_class.achievement_name).to eq('Lily Collector')
    end
  end

  describe '.points' do
    it 'returns the points value' do
      expect(described_class.points).to eq(100)
    end
  end

  describe '.requirements_text' do
    it 'returns the requirements description' do
      expect(described_class.requirements_text).to eq('Collect 10 lilies in a single game')
    end
  end

  describe '.check_progress' do
    context 'when game session has 10 or more lilies' do
      let(:game_session) { build(:game_session, lilies_collected: 10) }

      it 'returns true' do
        expect(described_class.check_progress(game_session)).to be true
      end
    end

    context 'when game session has more than 10 lilies' do
      let(:game_session) { build(:game_session, lilies_collected: 15) }

      it 'returns true' do
        expect(described_class.check_progress(game_session)).to be true
      end
    end

    context 'when game session has fewer than 10 lilies' do
      let(:game_session) { build(:game_session, lilies_collected: 9) }

      it 'returns false' do
        expect(described_class.check_progress(game_session)).to be false
      end
    end

    context 'when game session has no lilies' do
      let(:game_session) { build(:game_session, lilies_collected: 0) }

      it 'returns false' do
        expect(described_class.check_progress(game_session)).to be false
      end
    end

    context 'when lilies_collected is nil' do
      let(:game_session) { build(:game_session, lilies_collected: nil) }

      it 'returns false' do
        expect(described_class.check_progress(game_session)).to be false
      end
    end
  end

  describe 'LSP compliance' do
    it 'implements all required Achievement template methods' do
      expect(described_class).to respond_to(:achievement_type)
      expect(described_class).to respond_to(:achievement_name)
      expect(described_class).to respond_to(:points)
      expect(described_class).to respond_to(:requirements_text)
      expect(described_class).to respond_to(:check_progress)
    end
  end
end
